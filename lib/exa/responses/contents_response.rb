# frozen_string_literal: true

module Exa
  module Responses
    class ContentStatus < T::Struct
      const :id, String
      const :status, String
      const :error, T.nilable(T::Hash[Symbol, T.untyped])

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(id: sym[:id], status: sym[:status], error: sym[:error])
      end
    end

    class ContentsResponse < T::Struct
      const :request_id, T.nilable(String)
      const :results, T::Array[ResultWithContent]
      const :context, T.nilable(String)
      const :statuses, T.nilable(T::Array[ContentStatus])
      const :cost_dollars, T.nilable(CostDollars)

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          request_id: sym[:requestId],
          results: Array(sym[:results]).map { ResultWithContent.from_hash(_1) },
          context: sym[:context],
          statuses: sym[:statuses]&.map { ContentStatus.from_hash(_1) },
          cost_dollars: CostDollars.from_hash(sym[:costDollars])
        )
      end
    end
  end
end
