# frozen_string_literal: true

require "date"

module Exa
  module Types
    module Schema
      module_function

      HAS_DSPY_SCHEMA = begin
        require "dspy/schema"
        true
      rescue LoadError
        false
      end

      def to_json_schema(type)
        ensure_converter!
        DSPy::TypeSystem::SorbetJsonSchema.type_to_json_schema(type)
      end

      def maybe_convert(value)
        return nil if value.nil?
        return value if value.is_a?(Hash)
        return nil unless HAS_DSPY_SCHEMA

        if struct_class?(value)
          to_json_schema(value)
        elsif type_alias?(value)
          to_json_schema(value)
        elsif sorbet_type_object?(value)
          to_json_schema(value)
        else
          nil
        end
      end

      def struct_class?(value)
        value.is_a?(Class) && !value.name.nil? && (value < T::Struct || value < T::Enum)
      end

      def type_alias?(value)
        defined?(T::Private::Types::TypeAlias) && value.is_a?(T::Private::Types::TypeAlias)
      end

      def sorbet_type_object?(value)
        defined?(T::Types::Base) && value.is_a?(T::Types::Base)
      end

      def ensure_converter!
        return if HAS_DSPY_SCHEMA

        raise NotImplementedError,
              "Sorbet JSON Schema converter not available. Install dspy-schema to enable this feature."
      end
    end
  end
end
