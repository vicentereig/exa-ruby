# frozen_string_literal: true

module Exa
  module Types
    class ResearchCreateRequest < T::Struct
      include StructWrapper
      const :instructions, String
      const :model, T.nilable(ResearchModel)
      const :output_schema, T.nilable(T.untyped)
      const :events, T.nilable(T::Boolean)
      const :stream, T.nilable(T::Boolean)

      def to_payload
        Serializer.to_payload(self)
      end
    end
  end
end
