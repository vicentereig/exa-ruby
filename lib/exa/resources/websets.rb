# frozen_string_literal: true

require_relative "base"

module Exa
  module Resources
    class Websets < Base
      autoload :Monitors, "exa/resources/websets/monitors"

      attr_reader :monitors

      def initialize(client:)
        super
        @monitors = Exa::Resources::Websets::Monitors.new(client: client)
      end

      def create(params)
        client.request(method: :post, path: websets_path, body: params)
      end

      def list(params = nil)
        client.request(method: :get, path: websets_path, query: params)
      end

      def retrieve(webset_id)
        client.request(method: :get, path: websets_path(webset_id))
      end

      def update(webset_id, params)
        client.request(method: :patch, path: websets_path(webset_id), body: params)
      end

      def delete(webset_id)
        client.request(method: :delete, path: websets_path(webset_id))
      end

      private

      def websets_path(*parts)
        ["v0", "websets", *parts]
      end
    end
  end
end
