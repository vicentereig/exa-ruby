# frozen_string_literal: true

module Exa
  module Types
    module Serializer
      module_function

      def to_payload(value)
        schema_payload = Exa::Types::Schema.maybe_convert(value)
        return schema_payload unless schema_payload.nil?

        case value
        when StructWrapper
          value.__exa_attributes__
        when ::T::Struct
          serialize_struct(value)
        when Hash
          serialize_hash(value)
        when Array
          value.map { to_payload(_1) }
        when Symbol
          value.to_s
        when T::Enum
          value.serialize.to_s
        else
          value
        end
      end

      def serialize_struct(struct)
        struct.serialize.each_with_object({}) do |(key, val), acc|
          next if val.nil?
          method_name = key.to_sym
          raw_value = struct.respond_to?(method_name) ? struct.public_send(method_name) : nil
          schema_value = Exa::Types::Schema.maybe_convert(raw_value)
          acc[camelize(method_name)] = schema_value.nil? ? to_payload(val) : schema_value
        end
      end

      def serialize_hash(hash)
        hash.each_with_object({}) do |(key, val), acc|
          next if val.nil?
          acc[camelize(key)] = to_payload(val)
        end
      end

      def camelize(sym)
        key = sym.to_s
        return key if key.include?("$")
        parts = key.split("_")
        return key if parts.length == 1
        parts.first + parts[1..].map(&:capitalize).join
      end
    end

    module StructWrapper
      def to_payload
        Serializer.to_payload(self)
      end

      def __exa_attributes__
        Serializer.serialize_struct(self)
      end
    end
  end
end
