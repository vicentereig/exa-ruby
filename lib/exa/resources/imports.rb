# frozen_string_literal: true

require_relative "base"

module Exa
  module Resources
    class Imports < Base
      def create(params)
        client.request(
          method: :post,
          path: imports_path,
          body: params,
          response_model: Exa::Responses::ImportCreationResponse
        )
      end

      def list(params = nil)
        client.request(
          method: :get,
          path: imports_path,
          query: params,
          response_model: Exa::Responses::ImportListResponse
        )
      end

      def retrieve(id)
        client.request(
          method: :get,
          path: imports_path(id),
          response_model: Exa::Responses::Import
        )
      end

      def update(id, params)
        client.request(
          method: :patch,
          path: imports_path(id),
          body: params,
          response_model: Exa::Responses::Import
        )
      end

      def delete(id)
        client.request(
          method: :delete,
          path: imports_path(id),
          response_model: Exa::Responses::Import
        )
      end

      private

      def imports_path(*parts)
        ["v0", "imports", *parts]
      end
    end
  end
end
