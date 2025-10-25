# frozen_string_literal: true

require_relative "base"

module Exa
  module Resources
    class Webhooks < Base
      def create(params)
        client.request(method: :post, path: webhooks_path, body: params, response_model: Exa::Responses::RawResponse)
      end

      def list(params = nil)
        client.request(method: :get, path: webhooks_path, query: params, response_model: Exa::Responses::RawResponse)
      end

      def retrieve(id)
        client.request(method: :get, path: webhooks_path(id), response_model: Exa::Responses::RawResponse)
      end

      def update(id, params)
        client.request(method: :patch, path: webhooks_path(id), body: params, response_model: Exa::Responses::RawResponse)
      end

      def delete(id)
        client.request(method: :delete, path: webhooks_path(id), response_model: Exa::Responses::RawResponse)
      end

      def attempts(id, params = nil)
        client.request(method: :get, path: ["v0", "webhooks", id, "attempts"], query: params, response_model: Exa::Responses::RawResponse)
      end

      private

      def webhooks_path(*parts)
        ["v0", "webhooks", *parts]
      end
    end
  end
end
