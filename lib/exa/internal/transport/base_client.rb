# frozen_string_literal: true

require "uri"
require "cgi"
require "json"
require "securerandom"

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

        def request(method:, path:, query: nil, headers: nil, body: nil, unwrap: nil, stream: false, response_model: nil, request_options: nil)
          request_id = SecureRandom.uuid
          path_str = Array(path).join("/")
          endpoint = Exa::Instrumentation::Endpoint.from_path(path_str)
          start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          emit_request_start(request_id, endpoint, method, path_str)

          options = normalize_request_options(request_options)
          req = build_request(
            method: method,
            path: path_str,
            query: query,
            headers: headers,
            body: body,
            request_timeout: options[:timeout],
            idempotency_key: options[:idempotency_key]
          )

          begin
            status, response, stream_enum = send_request(req, max_retries: options[:max_retries] || max_retries)
            parsed_headers = Exa::Internal::Util.normalized_headers(response.each_header.to_h)

            result = if stream
                       Exa::Internal::Transport::Stream.new(headers: parsed_headers, stream: stream_enum)
                     else
                       decoded = Exa::Internal::Util.decode_content(parsed_headers, stream: stream_enum)
                       coerced = coerce_response(response_model, decoded)
                       unwrap ? dig(coerced, unwrap) : coerced
                     end

            emit_request_complete(request_id, endpoint, start_time, status, result)
            result
          rescue StandardError => e
            emit_request_error(request_id, endpoint, start_time, e)
            raise
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

        def build_request(method:, path:, query:, headers:, body:, request_timeout:, idempotency_key:)
          normalized_path = normalize_path(path)
          url = @base_url + normalized_path
          url.query = Exa::Internal::Util.build_query(query)

          header_overrides = headers ? headers.each_with_object({}) { |(k, v), acc| acc[k] = v unless v.nil? } : {}
          final_headers = PLATFORM_HEADERS.merge(default_headers).merge(header_overrides)
          final_headers["idempotency-key"] ||= idempotency_key if idempotency_key

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

          effective_timeout = request_timeout || timeout

          {
            method: method,
            url: url,
            headers: final_headers,
            body: payload,
            deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + effective_timeout,
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

        def send_request(request, retry_count: 0, max_retries: @max_retries)
          status, response, body_enum = @requester.execute(request)
          if should_retry?(status) && retry_count < max_retries
            sleep(retry_delay(retry_count, response))
            return send_request(request, retry_count: retry_count + 1, max_retries: max_retries)
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

        def retry_delay(retry_count, response = nil)
          header_delay = retry_after_delay(response)
          return header_delay if header_delay

          delay = initial_retry_delay * (2**retry_count)
          [delay, max_retry_delay].min
        end

        def retry_after_delay(response)
          return nil unless response
          value = nil
          if response.respond_to?(:[])
            value = response["Retry-After"] || response["retry-after"]
          end
          unless value
            if response.respond_to?(:each_header)
              response.each_header do |k, v|
                if k.downcase == "retry-after"
                  value = v
                  break
                end
              end
            end
          end
          return nil unless value
          parsed = Integer(value) rescue Float(value) rescue nil
          return nil unless parsed
          [parsed.to_f, max_retry_delay].min
        end

        def dig(obj, path)
          Array(path).reduce(obj) do |memo, key|
            memo.is_a?(Hash) ? memo[key] : nil
          end
        end

        def coerce_response(model, data)
          return data unless model
          return model.from_hash(data) if model.respond_to?(:from_hash)
          model.new(data)
        end

        def normalize_request_options(options)
          return {} if options.nil?
          opts = {}
          opts[:timeout] = options[:timeout] if options[:timeout]
          opts[:max_retries] = options[:max_retries] if options[:max_retries]
          opts[:idempotency_key] = options[:idempotency_key] if options[:idempotency_key]
          opts
        end

        def emit_request_start(request_id, endpoint, http_method, path)
          Exa.emit(
            "exa.request.start",
            Exa::Instrumentation::Events::RequestStart.new(
              request_id: request_id,
              endpoint: endpoint,
              http_method: http_method,
              path: path,
              timestamp: Process.clock_gettime(Process::CLOCK_MONOTONIC)
            )
          )
        end

        def emit_request_complete(request_id, endpoint, start_time, status, result)
          duration_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000
          cost_dollars = extract_cost_dollars(result)

          Exa.emit(
            "exa.request.complete",
            Exa::Instrumentation::Events::RequestComplete.new(
              request_id: request_id,
              endpoint: endpoint,
              duration_ms: duration_ms,
              status: status,
              cost_dollars: cost_dollars,
              timestamp: Process.clock_gettime(Process::CLOCK_MONOTONIC)
            )
          )
        end

        def emit_request_error(request_id, endpoint, start_time, error)
          duration_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000

          Exa.emit(
            "exa.request.error",
            Exa::Instrumentation::Events::RequestError.new(
              request_id: request_id,
              endpoint: endpoint,
              duration_ms: duration_ms,
              error_class: error.class.name,
              error_message: error.message,
              timestamp: Process.clock_gettime(Process::CLOCK_MONOTONIC)
            )
          )
        end

        def extract_cost_dollars(result)
          return nil unless result.respond_to?(:cost_dollars)
          cost = result.cost_dollars
          return nil unless cost

          # CostDollars struct has a total field
          cost.respond_to?(:total) ? cost.total : nil
        end
      end
    end
  end
end
