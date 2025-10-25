# frozen_string_literal: true

module Exa
  module Responses
    module ResultProps
      def self.included(base)
        base.const :title, T.nilable(String)
        base.const :url, T.nilable(String)
        base.const :published_date, T.nilable(String)
        base.const :author, T.nilable(String)
        base.const :score, T.nilable(Float)
        base.const :id, T.nilable(String)
        base.const :image, T.nilable(String)
        base.const :favicon, T.nilable(String)
      end
    end

    class Result < T::Struct
      include ResultProps

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          title: sym[:title],
          url: sym[:url],
          published_date: sym[:publishedDate],
          author: sym[:author],
          score: sym[:score]&.to_f,
          id: sym[:id],
          image: sym[:image],
          favicon: sym[:favicon]
        )
      end
    end

    class ResultWithContent < T::Struct
      include ResultProps
      const :text, T.nilable(String)
      const :highlights, T.nilable(T::Array[String])
      const :highlight_scores, T.nilable(T::Array[Float])
      const :summary, T.nilable(String)
      const :subpages, T.nilable(T::Array[Result])
      const :extras, T.nilable(T::Hash[String, T.untyped])

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        base = Result.from_hash(sym)
        attrs = base.serialize.transform_keys { _1.to_sym }
        attrs = attrs.merge(
          text: sym[:text],
          highlights: sym[:highlights],
          highlight_scores: sym[:highlightScores]&.map(&:to_f),
          summary: sym[:summary],
          subpages: sym[:subpages]&.map { ResultWithContent.from_hash(_1) },
          extras: sym[:extras]
        )
        new(**attrs)
      end
    end
  end
end
