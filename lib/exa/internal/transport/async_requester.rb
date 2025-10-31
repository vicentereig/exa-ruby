# frozen_string_literal: true

begin
  require "async"
  require "async/http/internet"
rescue LoadError => e
  raise LoadError, "Install the `async` and `async-http` gems to use AsyncRequester (caused by #{e.message})"
end

require "exa/errors"
require_relative "../util"

module Exa
  module Internal
    module Transport
      class AsyncRequester
        # Wraps an Async::HTTP::Response to mimic Net::HTTP's header API.
        class ResponseAdapter
          def initialize(response)
            @response = response
          end

          def each_header
            return enum_for(__method__) unless block_given?
            @response.headers.each do |key, value|
              Array(value).each { |v| yield(key, v) }
            end
          end

          def [](key)
            value = @response.headers[key]
            value.is_a?(Array) ? value.first : value
          end

          def finish
            @response.finish
          end
        end

        attr_reader :internet

        def initialize(internet: nil)
          @internet = internet || Async::HTTP::Internet.new
        end

        def execute(request)
          task = Async::Task.current?
          unless task
            raise Exa::Errors::ConfigurationError,
              "AsyncRequester must run inside an Async scheduler (wrap calls in `Async do ... end`)."
          end

          deadline = request.fetch(:deadline)
          response = with_timeout(deadline, request[:url]) do
            internet.call(
              request.fetch(:method).to_s.upcase,
              request.fetch(:url).to_s,
              request.fetch(:headers),
              request[:body]
            )
          end

          adapter = ResponseAdapter.new(response)

          body_enum = build_body_enum(response: response, deadline: deadline, url: request.fetch(:url).to_s)

          [Integer(response.status), adapter, body_enum]
        rescue Async::TimeoutError
          raise Exa::Errors::APITimeoutError.new("Request timed out", url: request[:url])
        rescue Exa::Errors::APIError, Exa::Errors::ConfigurationError
          raise
        rescue StandardError => e
          raise Exa::Errors::APIConnectionError.new(e.message, url: request[:url])
        end

        def close
          internet.close
        end

        private

        def build_body_enum(response:, deadline:, url:)
          body = response.body
          Exa::Internal::Util.fused_enum(
            Enumerator.new do |y|
              begin
                loop do
                  chunk = read_chunk(body: body, deadline: deadline, url: url)
                  break if chunk.nil?
                  y << chunk
                end
              ensure
                response.finish
              end
            end
          ) { response.finish }
        end

        def read_chunk(body:, deadline:, url:)
          remaining = remaining(deadline)
          return nil if remaining <= 0

          Async::Task.current.with_timeout(remaining) do
            body.read
          end
        rescue Async::TimeoutError
          raise Exa::Errors::APITimeoutError.new("Request timed out", url: url)
        end

        def with_timeout(deadline, url)
          remaining = remaining(deadline)
          raise Exa::Errors::APITimeoutError.new("Request timed out", url: url) if remaining <= 0

          Async::Task.current.with_timeout(remaining) { yield }
        end

        def remaining(deadline)
          deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end
      end
    end
  end
end
