# frozen_string_literal: true

require_relative "base"

module Exa
  module Resources
    class Websets < Base
      require_relative "websets/monitors"
      require_relative "websets/items"
      require_relative "websets/enrichments"

      attr_reader :monitors, :items, :enrichments

      def initialize(client:)
        super
        @monitors = Exa::Resources::Websets::Monitors.new(client: client)
        @items = Exa::Resources::Websets::Items.new(client: client)
        @enrichments = Exa::Resources::Websets::Enrichments.new(client: client)
      end

      def create(params)
        client.request(
          method: :post,
          path: websets_path,
          body: params,
          response_model: Exa::Responses::Webset
        )
      end

      def list(params = nil)
        client.request(
          method: :get,
          path: websets_path,
          query: params,
          response_model: Exa::Responses::WebsetListResponse
        )
      end

      def retrieve(webset_id)
        client.request(
          method: :get,
          path: websets_path(webset_id),
          response_model: Exa::Responses::Webset
        )
      end

      def update(webset_id, params)
        client.request(
          method: :patch,
          path: websets_path(webset_id),
          body: params,
          response_model: Exa::Responses::Webset
        )
      end

      def delete(webset_id)
        client.request(
          method: :delete,
          path: websets_path(webset_id),
          response_model: Exa::Responses::Webset
        )
      end

      def cancel(webset_id)
        client.request(
          method: :post,
          path: websets_path(webset_id, "cancel"),
          response_model: Exa::Responses::Webset
        )
      end

      def preview(params)
        client.request(
          method: :post,
          path: ["v0", "websets", "preview"],
          body: params,
          response_model: Exa::Responses::Webset
        )
      end

      private

      def websets_path(*parts)
        ["v0", "websets", *parts]
      end
    end
  end
end
