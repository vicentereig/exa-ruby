# frozen_string_literal: true

module Exa
  module Responses
    class Research < T::Struct
      const :id, String
      const :model, T.nilable(String)
      const :instructions, T.nilable(String)
      const :status, T.nilable(String)
      const :created_at, T.nilable(Integer)
      const :events, T::Array[T.untyped]
      const :operations, T::Array[T.untyped]
      const :output, T.nilable(T::Hash[Symbol, T.untyped])
      const :error, T.nilable(String)
      const :raw, T::Hash[Symbol, T.untyped]

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          id: sym[:researchId],
          model: sym[:model],
          instructions: sym[:instructions],
          status: sym[:status],
          created_at: sym[:createdAt]&.to_i,
          events: Array(sym[:events]),
          operations: Array(sym[:operations]),
          output: normalize_hash(sym[:output]),
          error: sym[:error],
          raw: sym
        )
      end

      def self.normalize_hash(value)
        return nil if value.nil?
        value.each_with_object({}) do |(k, v), acc|
          acc[k.to_sym] = v
        end
      end
    end

    class ResearchListResponse < T::Struct
      const :data, T::Array[Research]
      const :has_more, T.nilable(T::Boolean)
      const :next_cursor, T.nilable(String)

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          data: Array(sym[:data]).map { Research.from_hash(_1) },
          has_more: sym[:hasMore],
          next_cursor: sym[:nextCursor]
        )
      end
    end
  end
end
