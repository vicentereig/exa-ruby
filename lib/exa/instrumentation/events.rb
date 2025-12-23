# frozen_string_literal: true

module Exa
  module Instrumentation
    # Enum representing API endpoints for instrumentation
    class Endpoint < T::Enum
      enums do
        Search = new("search")
        Contents = new("contents")
        FindSimilar = new("findSimilar")
        Answer = new("answer")
        Research = new("research")
        ResearchList = new("research/list")
        ResearchCancel = new("research/cancel")
        WebsetCreate = new("websets/create")
        WebsetGet = new("websets/get")
        WebsetList = new("websets/list")
        WebsetDelete = new("websets/delete")
        WebsetUpdate = new("websets/update")
        WebsetSearch = new("websets/search")
        WebsetCancel = new("websets/cancel")
        WebsetItems = new("websets/items")
        WebsetEnrichments = new("websets/enrichments")
        Events = new("events")
        Webhooks = new("webhooks")
        Imports = new("imports")
        Unknown = new("unknown")
      end

      # Map a path string to an Endpoint enum value
      def self.from_path(path)
        normalized = Array(path).join("/").downcase

        case normalized
        when "search" then Search
        when "contents" then Contents
        when "findsimilar" then FindSimilar
        when "answer" then Answer
        when /^research$/ then Research
        when /^research\/[^\/]+$/ then Research
        when /^research\/[^\/]+\/cancel$/ then ResearchCancel
        when /^websets$/ then WebsetCreate
        when /^websets\/[^\/]+$/ then WebsetGet
        when /^websets\/[^\/]+\/items/ then WebsetItems
        when /^websets\/[^\/]+\/enrichments/ then WebsetEnrichments
        when /^websets\/[^\/]+\/search$/ then WebsetSearch
        when /^websets\/[^\/]+\/cancel$/ then WebsetCancel
        when /^events/ then Events
        when /^webhooks/ then Webhooks
        when /^imports/ then Imports
        else Unknown
        end
      end
    end

    # Type alias for responses that include cost information
    ResponseWithCost = T.type_alias do
      T.any(
        Exa::Responses::SearchResponse,
        Exa::Responses::FindSimilarResponse,
        Exa::Responses::ContentsResponse,
        Exa::Responses::AnswerResponse
      )
    end

    # Type alias for all response types
    AnyResponse = T.type_alias do
      T.any(
        Exa::Responses::SearchResponse,
        Exa::Responses::FindSimilarResponse,
        Exa::Responses::ContentsResponse,
        Exa::Responses::AnswerResponse,
        Exa::Responses::Research,
        Exa::Responses::ResearchListResponse
      )
    end

    module Events
      # Emitted when a request starts
      class RequestStart < T::Struct
        const :request_id, String
        const :endpoint, Endpoint
        const :http_method, Symbol
        const :path, String
        const :timestamp, Float
      end

      # Emitted when a request completes successfully
      class RequestComplete < T::Struct
        const :request_id, String
        const :endpoint, Endpoint
        const :duration_ms, Float
        const :status, Integer
        const :cost_dollars, T.nilable(Float)
        const :timestamp, Float
      end

      # Emitted when a request fails with an error
      class RequestError < T::Struct
        const :request_id, String
        const :endpoint, Endpoint
        const :duration_ms, Float
        const :error_class, String
        const :error_message, String
        const :timestamp, Float
      end
    end
  end
end
