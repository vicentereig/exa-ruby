# frozen_string_literal: true

module Exa
  module Responses
    # Detailed breakdown of costs by operation type within a single request iteration
    class CostBreakdownDetail < T::Struct
      const :neural_search, T.nilable(Float)
      const :deep_search, T.nilable(Float)
      const :content_text, T.nilable(Float)
      const :content_highlight, T.nilable(Float)
      const :content_summary, T.nilable(Float)

      def self.from_hash(hash)
        return nil unless hash
        sym = Helpers.symbolize_keys(hash)
        new(
          neural_search: sym[:neuralSearch]&.to_f,
          deep_search: sym[:deepSearch]&.to_f,
          content_text: sym[:contentText]&.to_f,
          content_highlight: sym[:contentHighlight]&.to_f,
          content_summary: sym[:contentSummary]&.to_f
        )
      end
    end

    # Cost breakdown for a single request iteration (search + contents)
    class CostBreakdown < T::Struct
      const :search, T.nilable(Float)
      const :contents, T.nilable(Float)
      const :breakdown, T.nilable(CostBreakdownDetail)

      def self.from_hash(hash)
        return nil unless hash
        sym = Helpers.symbolize_keys(hash)
        new(
          search: sym[:search]&.to_f,
          contents: sym[:contents]&.to_f,
          breakdown: CostBreakdownDetail.from_hash(sym[:breakdown])
        )
      end
    end

    # Standard price per request for different search operations
    class PerRequestPrices < T::Struct
      const :neural_search, T.nilable(Float)
      const :deep_search, T.nilable(Float)

      def self.from_hash(hash)
        return nil unless hash
        sym = Helpers.symbolize_keys(hash)
        new(
          neural_search: sym[:neuralSearch]&.to_f,
          deep_search: sym[:deepSearch]&.to_f
        )
      end
    end

    # Standard price per page for different content operations
    class PerPagePrices < T::Struct
      const :text, T.nilable(Float)
      const :highlight, T.nilable(Float)
      const :summary, T.nilable(Float)

      def self.from_hash(hash)
        return nil unless hash
        sym = Helpers.symbolize_keys(hash)
        new(
          text: sym[:text]&.to_f,
          highlight: sym[:highlight]&.to_f,
          summary: sym[:summary]&.to_f
        )
      end
    end

    # Complete cost information returned by Exa API responses
    class CostDollars < T::Struct
      const :total, T.nilable(Float)
      const :break_down, T.nilable(T::Array[CostBreakdown])
      const :per_request_prices, T.nilable(PerRequestPrices)
      const :per_page_prices, T.nilable(PerPagePrices)

      def self.from_hash(hash)
        return nil unless hash
        sym = Helpers.symbolize_keys(hash)
        new(
          total: sym[:total]&.to_f,
          break_down: sym[:breakDown]&.map { CostBreakdown.from_hash(_1) },
          per_request_prices: PerRequestPrices.from_hash(sym[:perRequestPrices]),
          per_page_prices: PerPagePrices.from_hash(sym[:perPagePrices])
        )
      end
    end
  end
end
