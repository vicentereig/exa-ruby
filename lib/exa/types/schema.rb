# frozen_string_literal: true

module Exa
  module Types
    module Schema
      module_function

      def to_json_schema(type)
        if defined?(DSPy::TypeSystem::SorbetJsonSchema)
          DSPy::TypeSystem::SorbetJsonSchema.type_to_json_schema(type)
        else
          raise NotImplementedError, "Sorbet JSON Schema converter not available. Install dspy-schema to enable this feature."
        end
      end
    end
  end
end
