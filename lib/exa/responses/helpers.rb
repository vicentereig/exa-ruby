# frozen_string_literal: true

module Exa
  module Responses
    module Helpers
      module_function

      def symbolize_keys(value)
        case value
        when Hash
          value.each_with_object({}) do |(k, v), acc|
            acc[k.to_sym] = symbolize_keys(v)
          end
        when Array
          value.map { symbolize_keys(_1) }
        else
          value
        end
      end
    end
  end
end
