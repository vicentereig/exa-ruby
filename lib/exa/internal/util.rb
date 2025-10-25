# frozen_string_literal: true

require "json"
require "stringio"
require "set"

module Exa
  module Internal
    module Util
      JSON_CONTENT = %r{application/(json|problem\+json)}i.freeze
      JSONL_CONTENT = %r{application/x-ndjson}i.freeze

      module_function

      def normalized_headers(headers)
        headers.each_with_object({}) do |(key, value), acc|
          next if value.nil?
          acc[key.to_s.downcase] = value.to_s
        end
      end

      def deep_merge_hash(base, extra)
        return base unless extra
        base.merge(extra) do |_k, old_val, new_val|
          if old_val.is_a?(Hash) && new_val.is_a?(Hash)
            deep_merge_hash(old_val, new_val)
          else
            new_val
          end
        end
      end

      def build_query(query)
        return nil if query.nil? || query.empty?
        URI.encode_www_form(query)
      end

      def decode_content(headers, stream:)
        case headers["content-type"]
        when JSON_CONTENT
          json = stream.to_a.join
          JSON.parse(json, symbolize_names: true)
        when JSONL_CONTENT
          stream.map { JSON.parse(_1, symbolize_names: true) }
        when /^text\/event-stream/
          decode_sse(stream)
        else
          StringIO.new(stream.to_a.join)
        end
      end

      def force_charset!(content_type, text:)
        return text unless content_type
        return text if text.encoding == Encoding::UTF_8
        if (match = /charset=([^;]+)/i.match(content_type))
          encoding = Encoding.find(match[1])
          text.force_encoding(encoding)
        end
        text
      rescue ArgumentError
        text
      end

      def decode_lines(enum)
        Enumerator.new do |y|
          buffer = String.new
          enum.each do |chunk|
            buffer << chunk
            while (idx = buffer.index(/\r?\n/))
              y << buffer.slice!(0..idx)
            end
          end
          y << buffer unless buffer.empty?
        end
      end

      def decode_sse(enum)
        lines = decode_lines(enum)
        Enumerator.new do |y|
          event = {event: nil, data: String.new, id: nil, retry: nil}
          lines.each do |line|
            stripped = line.strip
            if stripped.empty?
              y << event.dup if event[:data]&.length&.positive?
              event = {event: nil, data: String.new, id: nil, retry: nil}
              next
            end

            case stripped
            when /^event:(.*)$/
              event[:event] = Regexp.last_match(1).strip
            when /^data:(.*)$/
              event[:data] << Regexp.last_match(1).lstrip << "\n"
            when /^id:(.*)$/
              event[:id] = Regexp.last_match(1).strip
            when /^retry:(\d+)$/
              event[:retry] = Regexp.last_match(1).to_i
            end
          end
        end
      end

      def fused_enum(enum, &on_close)
        closed = false
        Enumerator.new do |y|
          break if closed
          enum.each { y << _1 }
        ensure
          unless closed
            closed = true
            on_close&.call
          end
        end
      end

      def close_fused!(enum)
        return unless enum.respond_to?(:rewind)
        enum.rewind
        begin
          enum.each { break }
        rescue StopIteration
        end
      end
    end
  end
end
