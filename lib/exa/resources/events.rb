# frozen_string_literal: true

require_relative "base"

module Exa
  module Resources
    class Events < Base
      def list(params = nil)
        client.request(method: :get, path: events_path, query: params, response_model: Exa::Responses::RawResponse)
      end

      def retrieve(event_id)
        client.request(method: :get, path: events_path(event_id), response_model: Exa::Responses::RawResponse)
      end

      private

      def events_path(*parts)
        ["v0", "events", *parts]
      end
    end
  end
end
