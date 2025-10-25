# frozen_string_literal: true

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
