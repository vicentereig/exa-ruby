# frozen_string_literal: true

require "test_helper"

class EventsResourceTest < Minitest::Test
  def setup
    requester = TestSupport::FakeRequester.new([])
    @client = Exa::Client.new(api_key: "abc", requester: requester, base_url: "https://api.test")
    @resource = @client.events
    @requester = requester
  end

  def test_list_and_retrieve
    @requester.push_responder(json_response(event_list_payload))
    response = @resource.list(limit: 5)
    assert_kind_of Exa::Responses::EventListResponse, response
    assert_equal "https://api.test/v0/events?limit=5", @requester.requests.last[:url].to_s

    @requester.push_responder(json_response(event_payload))
    event = @resource.retrieve("evt_123")
    assert_kind_of Exa::Responses::Event, event
    assert_equal "https://api.test/v0/events/evt_123", @requester.requests.last[:url].to_s
    assert_equal "webset.created", event.type
    assert_equal "ws_123", event.data[:websetId]
  end

  private

  def event_payload
    {
      id: "evt_123",
      object: "event",
      type: "webset.created",
      data: {websetId: "ws_123"},
      createdAt: "2024-01-01T00:00:00Z"
    }
  end

  def event_list_payload
    {
      data: [event_payload],
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
