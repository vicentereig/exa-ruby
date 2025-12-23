# frozen_string_literal: true

module Exa
  module Responses
    class AnswerCitation < T::Struct
      const :id, T.nilable(String)
      const :url, T.nilable(String)
      const :title, T.nilable(String)
      const :author, T.nilable(String)
      const :published_date, T.nilable(String)
      const :text, T.nilable(String)
      const :image, T.nilable(String)
      const :favicon, T.nilable(String)

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          id: sym[:id],
          url: sym[:url],
          title: sym[:title],
          author: sym[:author],
          published_date: sym[:publishedDate],
          text: sym[:text],
          image: sym[:image],
          favicon: sym[:favicon]
        )
      end
    end

    class AnswerResponse < T::Struct
      const :answer, T.nilable(String)
      const :citations, T::Array[AnswerCitation]
      const :cost_dollars, T.nilable(CostDollars)

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          answer: sym[:answer],
          citations: Array(sym[:citations]).map { AnswerCitation.from_hash(_1) },
          cost_dollars: CostDollars.from_hash(sym[:costDollars])
        )
      end
    end
  end
end
