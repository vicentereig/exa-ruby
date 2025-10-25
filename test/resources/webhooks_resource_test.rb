# frozen_string_literal: true

require "test_helper"

class WebhooksResourceTest < Minitest::Test
  def setup
    requester = TestSupport::FakeRequester.new([])
    @client = Exa::Client.new(api_key: "abc", requester: requester, base_url: "https://api.test")
    @resource = @client.webhooks
    @requester = requester
  end

  def test_crud_paths
    @requester.push_responder(json_response(webhook_payload))
    created = @resource.create(url: "https://example.com", events: ["webset.created"])
    assert_kind_of Exa::Responses::Webhook, created
    assert_equal "https://api.test/v0/webhooks", @requester.requests.last[:url].to_s

    @requester.push_responder(json_response(webhook_list_payload))
    listing = @resource.list
    assert_kind_of Exa::Responses::WebhookListResponse, listing
    assert_equal "https://api.test/v0/webhooks", @requester.requests.last[:url].to_s

    @requester.push_responder(json_response(webhook_payload))
    retrieved = @resource.retrieve("wh_123")
    assert_kind_of Exa::Responses::Webhook, retrieved
    assert_equal "https://api.test/v0/webhooks/wh_123", @requester.requests.last[:url].to_s

    @requester.push_responder(json_response(webhook_payload(url: "https://new")))
    updated = @resource.update("wh_123", url: "https://new")
    assert_kind_of Exa::Responses::Webhook, updated
    assert_equal :patch, @requester.requests.last[:method]

    @requester.push_responder(json_response(webhook_payload(status: "inactive")))
    deleted = @resource.delete("wh_123")
    assert_kind_of Exa::Responses::Webhook, deleted
    assert_equal :delete, @requester.requests.last[:method]
  end

  def test_attempts
    @requester.push_responder(json_response(webhook_attempt_list_payload))
    attempts = @resource.attempts("wh_123", limit: 2)
    assert_kind_of Exa::Responses::WebhookAttemptListResponse, attempts
    assert_equal "https://api.test/v0/webhooks/wh_123/attempts?limit=2", @requester.requests.last[:url].to_s
  end

  private

  def webhook_payload(overrides = {})
    {
      id: "wh_123",
      object: "webhook",
      status: "active",
      events: ["webset.created"],
      url: "https://example.com",
      secret: "secret",
      metadata: {"env" => "test"},
      createdAt: "2024-01-01T00:00:00Z",
      updatedAt: "2024-01-01T01:00:00Z"
    }.merge(overrides)
  end

  def webhook_list_payload
    {
      data: [webhook_payload],
      hasMore: false,
      nextCursor: nil
    }
  end

  def webhook_attempt_list_payload
    {
      data: [
        {
          id: "wha_1",
          object: "webhook_attempt",
          eventId: "evt_123",
          eventType: "webset.created",
          webhookId: "wh_123",
          url: "https://example.com",
          successful: true,
          responseHeaders: {"content-type" => "application/json"},
          responseBody: "{}",
          responseStatusCode: 200,
          attempt: 1,
          attemptedAt: "2024-01-01T00:02:00Z"
        }
      ],
      hasMore: false,
      nextCursor: nil
    }
  end

  def json_response(body)
    lambda do |_req|
      response = TestSupport::FakeResponse.new("200", {"content-type" => "application/json"})
      [200, response, [body.to_json].each]
    end
  end
end
