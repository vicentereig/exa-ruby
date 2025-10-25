# frozen_string_literal: true

module Exa
  module Responses
    class Webhook < T::Struct
      const :id, String
      const :object, T.nilable(String)
      const :status, T.nilable(String)
      const :events, T::Array[String]
      const :url, T.nilable(String)
      const :secret, T.nilable(String)
      const :metadata, T.nilable(T::Hash[String, String])
      const :created_at, T.nilable(String)
      const :updated_at, T.nilable(String)

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          id: sym[:id],
          object: sym[:object],
          status: sym[:status],
          events: Array(sym[:events]).map(&:to_s),
          url: sym[:url],
          secret: sym[:secret],
          metadata: Helpers.stringify_string_hash(sym[:metadata]),
          created_at: sym[:createdAt],
          updated_at: sym[:updatedAt]
        )
      end
    end

    class WebhookListResponse < T::Struct
      const :data, T::Array[Webhook]
      const :has_more, T.nilable(T::Boolean)
      const :next_cursor, T.nilable(String)

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          data: Array(sym[:data]).map { Webhook.from_hash(_1) },
          has_more: sym[:hasMore],
          next_cursor: sym[:nextCursor]
        )
      end
    end

    class WebhookAttempt < T::Struct
      const :id, String
      const :object, T.nilable(String)
      const :event_id, T.nilable(String)
      const :event_type, T.nilable(String)
      const :webhook_id, T.nilable(String)
      const :url, T.nilable(String)
      const :successful, T.nilable(T::Boolean)
      const :response_headers, T.nilable(T::Hash[String, String])
      const :response_body, T.nilable(String)
      const :response_status_code, T.nilable(Integer)
      const :attempt, T.nilable(Integer)
      const :attempted_at, T.nilable(String)

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          id: sym[:id],
          object: sym[:object],
          event_id: sym[:eventId],
          event_type: sym[:eventType],
          webhook_id: sym[:webhookId],
          url: sym[:url],
          successful: sym[:successful],
          response_headers: Helpers.stringify_string_hash(sym[:responseHeaders]),
          response_body: sym[:responseBody],
          response_status_code: sym[:responseStatusCode]&.to_i,
          attempt: sym[:attempt]&.to_i,
          attempted_at: sym[:attemptedAt]
        )
      end
    end

    class WebhookAttemptListResponse < T::Struct
      const :data, T::Array[WebhookAttempt]
      const :has_more, T.nilable(T::Boolean)
      const :next_cursor, T.nilable(String)

      def self.from_hash(hash)
        sym = Helpers.symbolize_keys(hash)
        new(
          data: Array(sym[:data]).map { WebhookAttempt.from_hash(_1) },
          has_more: sym[:hasMore],
          next_cursor: sym[:nextCursor]
        )
      end
    end
  end
end
