# frozen_string_literal: true

require_relative "base"

module Exa
  module Resources
    class Research < Base
      def create(params)
        payload = serialize(Exa::Types::ResearchCreateRequest, params)
        client.request(method: :post, path: "research", body: payload)
      end

      def list(params = nil)
        client.request(method: :get, path: "research", query: params)
      end

      def get(research_id, stream: false, events: nil)
        query = {}
        query[:events] = events unless events.nil?
        query[:stream] = stream ? "true" : nil
        client.request(method: :get, path: ["research", research_id], query: query.compact, stream: stream)
      end

      def cancel(research_id)
        client.request(method: :post, path: ["research", research_id, "cancel"])
      end
    end
  end
end
