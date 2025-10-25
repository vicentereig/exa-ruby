# frozen_string_literal: true

require "uri"
require "cgi"
require "json"

require_relative "../util"
require_relative "pooled_net_requester"
require_relative "stream"
require "exa/errors"

module Exa
  module Internal
    module Transport
      class BaseClient
        PLATFORM_HEADERS = {
          "x-stainless-lang" => "ruby",
          "x-stainless-runtime" => RUBY_ENGINE,
          "x-stainless-runtime-version" => RUBY_ENGINE_VERSION
        }.freeze

        DEFAULT_MAX_RETRIES = 2
        DEFAULT_TIMEOUT = 120.0
        DEFAULT_INITIAL_RETRY_DELAY = 0.5
        DEFAULT_MAX_RETRY_DELAY = 8.0

        attr_reader :base_url, :timeout, :max_retries, :initial_retry_delay, :max_retry_delay, :headers, :requester

        def initialize(
          base_url:,
          timeout: DEFAULT_TIMEOUT,
          max_retries: DEFAULT_MAX_RETRIES,
          initial_retry_delay: DEFAULT_INITIAL_RETRY_DELAY,
          max_retry_delay: DEFAULT_MAX_RETRY_DELAY,
          headers: {},
          requester: Exa::Internal::Transport::PooledNetRequester.new
        )
          @base_url = URI(base_url)
          @timeout = timeout
          @max_retries = max_retries
          @initial_retry_delay = initial_retry_delay
          @max_retry_delay = max_retry_delay
          @headers = headers || {}
          @requester = requester
        end

        def request(method:, path:, query: nil, headers: nil, body: nil, unwrap: nil, stream: false)
          req = build_request(
            method: method,
            path: Array(path).join("/"),
            query: query,
            headers: headers,
            body: body
          )

          _, response, stream_enum = send_request(req)
          parsed_headers = Exa::Internal::Util.normalized_headers(response.each_header.to_h)

          if stream
            Exa::Internal::Transport::Stream.new(headers: parsed_headers, stream: stream_enum)
          else
            decoded = Exa::Internal::Util.decode_content(parsed_headers, stream: stream_enum)
            unwrap ? dig(decoded, unwrap) : decoded
          end
        end

        private

        def normalize_path(path)
          segments = Array(path).flat_map do |segment|
            next [] if segment.nil?
            segment.to_s.split("/")
          end
          cleaned = segments.reject(&:empty?)
          return "" if cleaned.empty?
          cleaned.join("/")
        end

        def build_request(method:, path:, query:, headers:, body:)
          normalized_path = normalize_path(path)
          url = @base_url + normalized_path
          url.query = Exa::Internal::Util.build_query(query)

          header_overrides = headers ? headers.each_with_object({}) { |(k, v), acc| acc[k] = v unless v.nil? } : {}
          final_headers = PLATFORM_HEADERS.merge(default_headers).merge(header_overrides)

          payload = case body
                    when nil
                      nil
                    when String
                      final_headers["content-type"] ||= "application/json"
                      body
                    else
                      final_headers["content-type"] ||= "application/json"
                      JSON.generate(body)
                    end

          {
            method: method,
            url: url,
            headers: final_headers,
            body: payload,
            deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout,
            max_retries: max_retries
          }
        end

        def default_headers
          merged = headers.merge(auth_headers)
          merged.each_with_object({}) do |(k, v), acc|
            next if v.nil?
            acc[k] = v
          end
        end

        def auth_headers
          {}
        end

        def send_request(request, retry_count: 0)
          status, response, body_enum = @requester.execute(request)
          if should_retry?(status) && retry_count < max_retries
            sleep(retry_delay(retry_count))
            return send_request(request, retry_count: retry_count + 1)
          end

          if status >= 400
            decoded_headers = Exa::Internal::Util.normalized_headers(response.each_header.to_h)
            payload = Exa::Internal::Util.decode_content(decoded_headers, stream: body_enum)
            Exa::Errors::APIStatusError.raise!(
              url: request[:url],
              status: status,
              headers: decoded_headers,
              body: payload
            )
          end

          [status, response, body_enum]
        rescue Exa::Errors::APITimeoutError, Exa::Errors::APIConnectionError, Exa::Errors::APIStatusError
          raise
        rescue Timeout::Error
          raise Exa::Errors::APITimeoutError.new("Request timed out", url: request[:url])
        rescue StandardError => e
          raise Exa::Errors::APIConnectionError.new(e.message, url: request[:url])
        end

        def should_retry?(status)
          [408, 409, 429].include?(status) || status >= 500
        end

        def retry_delay(retry_count)
          delay = initial_retry_delay * (2**retry_count)
          [delay, max_retry_delay].min
        end

        def dig(obj, path)
          Array(path).reduce(obj) do |memo, key|
            memo.is_a?(Hash) ? memo[key] : nil
          end
        end
      end
    end
  end
end
