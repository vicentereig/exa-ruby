# frozen_string_literal: true

module Exa
  module Responses
    class Event < T::Struct
      const :id, String
      const :object, T.nilable(String)
      const :type, String
      const :data, T.nilable(T.untyped)
      const :created_at, T.nilable(String)
      const :raw, T::Hash[Symbol, T.untyped]

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        data = sym[:data]
        normalized_data = data.is_a?(Hash) ? Helpers.symbolize_keys(data) : data
        new(
          id: sym[:id],
          object: sym[:object],
          type: sym[:type],
          data: normalized_data,
          created_at: sym[:createdAt],
          raw: sym
        )
      end
    end

    class EventListResponse < T::Struct
      const :data, T::Array[Event]
      const :has_more, T.nilable(T::Boolean)
      const :next_cursor, T.nilable(String)

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          data: Array(sym[:data]).map { Event.from_hash(_1) },
          has_more: sym[:hasMore],
          next_cursor: sym[:nextCursor]
        )
      end
    end
  end
end
