# frozen_string_literal: true

require "net/http"
require "uri"
require "connection_pool"
require "etc"

module Exa
  module Internal
    module Transport
      class PooledNetRequester
        KEEP_ALIVE_TIMEOUT = 30
        DEFAULT_MAX_CONNECTIONS = [Etc.nprocessors, 99].max

        def initialize(size: DEFAULT_MAX_CONNECTIONS)
          @size = size
          @mutex = Mutex.new
          @pools = {}
        end

        def execute(request)
          url = request.fetch(:url)
          deadline = request.fetch(:deadline)

          pool_for(url).with(timeout: remaining(deadline)) do |conn|
            req, body_closer = build_request(request) do
              calibrate_socket_timeout(conn, deadline)
            end

            calibrate_socket_timeout(conn, deadline)
            start_connection(conn)
            calibrate_socket_timeout(conn, deadline)

            enum = Enumerator.new do |y|
              conn.request(req) do |resp|
                y << [req, resp]
                resp.read_body do |chunk|
                  y << chunk.force_encoding(Encoding::BINARY)
                end
              end
            rescue Timeout::Error
              raise Exa::Errors::APITimeoutError.new("Request timed out", url: url)
            rescue StandardError => e
              raise Exa::Errors::APIConnectionError.new(e.message, url: url)
            ensure
              body_closer&.call
            end

            _, response = enum.next
            body = Exa::Internal::Util.fused_enum(enum)
            [Integer(response.code), response, body]
          end
        end

        private

        def pool_for(url)
          origin = uri_origin(url)
          @mutex.synchronize do
            @pools[origin] ||= ConnectionPool.new(size: @size) { build_connection(url) }
          end
        end

        def build_connection(url)
          conn = Net::HTTP.new(url.host, url.port)
          conn.use_ssl = url.scheme == "https"
          conn.keep_alive_timeout = KEEP_ALIVE_TIMEOUT
          conn
        end

        def start_connection(conn)
          return if conn.started?
          conn.start
        end

        def calibrate_socket_timeout(conn, deadline)
          remaining = remaining(deadline)
          conn.open_timeout = remaining
          conn.read_timeout = remaining
          conn.write_timeout = remaining if conn.respond_to?(:write_timeout=)
        end

        def remaining(deadline)
          [deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC), 0.001].max
        end

        def build_request(request)
          method, url, headers, body = request.values_at(:method, :url, :headers, :body)
          req = Net::HTTPGenericRequest.new(method.to_s.upcase, !body.nil?, method != :head, URI(url.to_s))
          headers.each { req[_1] = _2 }

          case body
          when nil
          when String
            req.body = body
            req["content-length"] = body.bytesize.to_s
          when StringIO
            req.body_stream = body
            req["content-length"] = body.size.to_s
          else
            req.body = body
          end

          [req, req.body_stream&.method(:close)]
        end

        def uri_origin(uri)
          [uri.scheme, uri.host, uri.port].join(":")
        end
      end
    end
  end
end
