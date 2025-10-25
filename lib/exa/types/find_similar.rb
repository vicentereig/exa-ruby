# frozen_string_literal: true

module Exa
  module Types
    class FindSimilarRequest < T::Struct
      include StructWrapper
      const :url, String
      const :num_results, T.nilable(Integer)
      const :include_domains, T.nilable(T::Array[String])
      const :exclude_domains, T.nilable(T::Array[String])
      const :start_crawl_date, T.nilable(String)
      const :end_crawl_date, T.nilable(String)
      const :start_published_date, T.nilable(String)
      const :end_published_date, T.nilable(String)
      const :include_text, T.nilable(T::Array[String])
      const :exclude_text, T.nilable(T::Array[String])
      const :exclude_source_domain, T.nilable(T::Boolean)
      const :category, T.nilable(Category)
      const :flags, T.nilable(T::Array[String])

      def to_payload
        Serializer.to_payload(self)
      end
    end
  end
end
