# frozen_string_literal: true

module Exa
  module Types
    class ContentsRequest < T::Struct
      include StructWrapper
      const :urls, T::Array[String]
      const :text, T.nilable(T.any(T::Boolean, TextContentsOptions))
      const :highlights, T.nilable(T.any(T::Boolean, HighlightsContentsOptions))
      const :summary, T.nilable(T.any(T::Boolean, SummaryContentsOptions))
      const :context, T.nilable(T.any(T::Boolean, ContextOptions))
      const :metadata, T.nilable(T::Boolean)
      const :livecrawl_timeout, T.nilable(Integer)
      const :livecrawl, T.nilable(LivecrawlMode)
      const :filter_empty_results, T.nilable(T::Boolean)
      const :subpages, T.nilable(Integer)
      const :subpage_target, T.nilable(T.any(String, T::Array[String]))
      const :extras, T.nilable(ExtrasOptions)

      def to_payload
        Serializer.to_payload(self)
      end
    end
  end
end
