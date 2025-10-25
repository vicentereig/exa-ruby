# frozen_string_literal: true

module Exa
  module Types
    class AnswerSearchOptions < T::Struct
      include StructWrapper
      include SearchOptionProps
    end

    class AnswerSummaryOptions < T::Struct
      include StructWrapper
      const :schema, T.nilable(T.untyped)
    end

    class AnswerRequest < T::Struct
      include StructWrapper
      const :query, String
      const :summary, T.nilable(AnswerSummaryOptions)
      const :search_options, T.nilable(AnswerSearchOptions)

      def to_payload
        payload = Serializer.to_payload(self)
        if payload["searchOptions"].is_a?(Hash)
          payload["searchOptions"] = payload["searchOptions"].merge("query" => query)
        end
        payload
      end
    end
  end
end
