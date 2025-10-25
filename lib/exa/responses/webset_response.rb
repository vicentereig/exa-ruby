# frozen_string_literal: true

module Exa
  module Responses
    class Webset < T::Struct
      const :id, String
      const :object, T.nilable(String)
      const :status, T.nilable(String)
      const :external_id, T.nilable(String)
      const :title, T.nilable(String)
      const :searches, T::Array[T.untyped]
      const :imports, T::Array[T.untyped]
      const :enrichments, T::Array[T.untyped]
      const :monitors, T::Array[T.untyped]
      const :streams, T::Array[T.untyped]
      const :metadata, T.nilable(T::Hash[String, String])
      const :created_at, T.nilable(String)
      const :updated_at, T.nilable(String)
      const :raw, T::Hash[Symbol, T.untyped]

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          id: sym[:id],
          object: sym[:object],
          status: sym[:status],
          external_id: sym[:externalId],
          title: sym[:title],
          searches: Array(sym[:searches]),
          imports: Array(sym[:imports]),
          enrichments: Array(sym[:enrichments]),
          monitors: Array(sym[:monitors]),
          streams: Array(sym[:streams]),
          metadata: Helpers.stringify_string_hash(sym[:metadata]),
          created_at: sym[:createdAt],
          updated_at: sym[:updatedAt],
          raw: sym
        )
      end
    end

    class WebsetListResponse < T::Struct
      const :data, T::Array[Webset]
      const :has_more, T.nilable(T::Boolean)
      const :next_cursor, T.nilable(String)

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          data: Array(sym[:data]).map { Webset.from_hash(_1) },
          has_more: sym[:hasMore],
          next_cursor: sym[:nextCursor]
        )
      end
    end
  end
end
