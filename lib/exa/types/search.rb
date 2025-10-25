# frozen_string_literal: true

module Exa
  module Types
    module SearchOptionProps
      def self.included(base)
        base.const :num_results, T.nilable(Integer)
        base.const :include_domains, T.nilable(T::Array[String])
        base.const :exclude_domains, T.nilable(T::Array[String])
        base.const :start_crawl_date, T.nilable(String)
        base.const :end_crawl_date, T.nilable(String)
        base.const :start_published_date, T.nilable(String)
        base.const :end_published_date, T.nilable(String)
        base.const :include_text, T.nilable(T::Array[String])
        base.const :exclude_text, T.nilable(T::Array[String])
        base.const :use_autoprompt, T.nilable(T::Boolean)
        base.const :type, T.nilable(SearchType)
        base.const :category, T.nilable(Category)
        base.const :flags, T.nilable(T::Array[String])
        base.const :moderation, T.nilable(T::Boolean)
        base.const :user_location, T.nilable(String)
        base.const :livecrawl, T.nilable(LivecrawlMode)
        base.const :livecrawl_timeout, T.nilable(Integer)
        base.const :subpages, T.nilable(Integer)
        base.const :subpage_target, T.nilable(T.any(String, T::Array[String]))
        base.const :extras, T.nilable(ExtrasOptions)
        base.const :text, T.nilable(T.any(T::Boolean, TextContentsOptions))
        base.const :highlights, T.nilable(T.any(T::Boolean, HighlightsContentsOptions))
        base.const :summary, T.nilable(T.any(T::Boolean, SummaryContentsOptions))
        base.const :context, T.nilable(T.any(T::Boolean, ContextOptions))
      end
    end

    class TextContentsOptions < T::Struct
      include StructWrapper
      const :max_characters, T.nilable(Integer)
      const :include_html_tags, T.nilable(T::Boolean)
    end

    class HighlightsContentsOptions < T::Struct
      include StructWrapper
      const :query, T.nilable(String)
      const :num_sentences, T.nilable(Integer)
      const :highlights_per_url, T.nilable(Integer)
    end

    class SummaryContentsOptions < T::Struct
      include StructWrapper
      const :query, T.nilable(String)
      const :schema, T.nilable(T.untyped)
    end

    class ContextOptions < T::Struct
      include StructWrapper
      const :max_characters, T.nilable(Integer)
    end

    class ExtrasOptions < T::Struct
      include StructWrapper
      const :links, T.nilable(Integer)
      const :image_links, T.nilable(Integer)
    end

    class SearchRequest < T::Struct
      include StructWrapper
      include SearchOptionProps
      const :query, String

      def to_payload
        Serializer.to_payload(self)
      end
    end
  end
end
