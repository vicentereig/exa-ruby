# frozen_string_literal: true

require "json"

module Exa
  module Internal
    module Transport
      class Stream
        include Enumerable

        def initialize(headers:, stream:)
          @headers = headers
          @stream = stream
        end

        def each(&blk)
          return enum_for(__method__) unless block_given?
          @stream.each(&blk)
        end

        def each_line(&blk)
          return enum_for(__method__) unless block_given?
          enumerator = Exa::Internal::Util.decode_lines(@stream)
          begin
            enumerator.each do |line|
              yield line.chomp
            end
          ensure
            close
          end
        end

        def each_json_line(symbolize: true, &blk)
          return enum_for(__method__, symbolize: symbolize) unless block_given?
          each_line do |line|
            next if line.strip.empty?
            yield JSON.parse(line, symbolize_names: symbolize)
          end
        end

        def each_event(&blk)
          return enum_for(__method__) unless block_given?
          sse = Exa::Internal::Util.decode_sse(@stream)
          begin
            sse.each do |event|
              payload = event[:data]
              payload = payload.chomp if payload
              yield(event.merge(data: payload))
            end
          ensure
            close
          end
        end

        def each_event_json(symbolize: true, &blk)
          return enum_for(__method__, symbolize: symbolize) unless block_given?
          each_event do |event|
            data = event[:data]
            next if data.nil? || data.empty?
            yield event.merge(data: JSON.parse(data, symbolize_names: symbolize))
          end
        end

        def close
          Exa::Internal::Util.close_fused!(@stream)
        end

        def content_type
          @headers["content-type"]
        end
      end
    end
  end
end
