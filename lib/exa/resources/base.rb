# frozen_string_literal: true

module Exa
  module Resources
    class Base
      attr_reader :client

      def initialize(client:)
        @client = client
      end

      private

      def serialize(struct_class, params)
        case params
        when struct_class
          params.to_payload
        when Hash
          struct_class.new(**params).to_payload
        else
          raise ArgumentError, "Expected #{struct_class} or Hash, got #{params.class}"
        end
      end
    end
  end
end
