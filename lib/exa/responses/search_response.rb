# frozen_string_literal: true

module Exa
  module Responses
    class SearchResponse < T::Struct
      const :request_id, T.nilable(String)
      const :resolved_search_type, T.nilable(String)
      const :search_type, T.nilable(String)
      const :results, T::Array[ResultWithContent]
      const :context, T.nilable(String)
      const :cost_dollars, T.nilable(T.any(Float, T::Hash[Symbol, T.untyped]))

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          request_id: sym[:requestId],
          resolved_search_type: sym[:resolvedSearchType],
          search_type: sym[:searchType],
          results: Array(sym[:results]).map { ResultWithContent.from_hash(_1) },
          context: sym[:context],
          cost_dollars: normalize_cost(sym[:costDollars])
        )
      end

      def self.normalize_cost(value)
        case value
        when nil
          nil
        when Numeric
          value.to_f
        when Hash
          Exa::Responses::Helpers.symbolize_keys(value)
        else
          value
        end
      end
    end

    class FindSimilarResponse < T::Struct
      const :request_id, T.nilable(String)
      const :results, T::Array[ResultWithContent]
      const :context, T.nilable(String)
      const :cost_dollars, T.nilable(Float)

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          request_id: sym[:requestId],
          results: Array(sym[:results]).map { ResultWithContent.from_hash(_1) },
          context: sym[:context],
          cost_dollars: sym[:costDollars]&.to_f
        )
      end
    end
  end
end
