# frozen_string_literal: true

require_relative "base"

module Exa
  module Resources
    class Search < Base
      def search(params)
        payload = serialize(Exa::Types::SearchRequest, params)
        client.request(method: :post, path: "search", body: payload, response_model: Exa::Responses::SearchResponse)
      end

      def contents(params)
        payload = serialize(Exa::Types::ContentsRequest, params)
        client.request(method: :post, path: "contents", body: payload, response_model: Exa::Responses::ContentsResponse)
      end

      def find_similar(params)
        payload = serialize(Exa::Types::FindSimilarRequest, params)
        client.request(method: :post, path: "findSimilar", body: payload, response_model: Exa::Responses::FindSimilarResponse)
      end

      def answer(params)
        stream = stream_requested?(params)
        normalized = normalize_nested_struct(params, :search_options, Exa::Types::AnswerSearchOptions)
        payload = serialize(Exa::Types::AnswerRequest, normalized)
        client.request(
          method: :post,
          path: "answer",
          body: payload,
          stream: stream,
          response_model: stream ? nil : Exa::Responses::AnswerResponse
        )
      end

      private

      def normalize_nested_struct(params, key, struct_class)
        return params unless params.is_a?(Hash)

        value = params[key] || params[key.to_s]
        return params if value.nil? || value.is_a?(struct_class)

        merged = params.dup
        merged[key] = struct_class.new(**value)
        merged.delete(key.to_s)
        merged
      end

      def stream_requested?(params)
        case params
        when Hash
          value = params[:stream]
          value = params["stream"] if value.nil?
          !!value
        when Exa::Types::AnswerRequest
          !!params.stream
        else
          false
        end
      end
    end
  end
end
