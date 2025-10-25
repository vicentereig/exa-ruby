# frozen_string_literal: true

module Exa
  module Responses
    class RawResponse < T::Struct
      const :raw, T::Hash[Symbol, T.untyped]

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(raw: sym)
      end
    end
  end
end
