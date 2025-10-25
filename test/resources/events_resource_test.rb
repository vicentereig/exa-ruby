# frozen_string_literal: true

require "test_helper"

class EventsResourceTest < Minitest::Test
  def setup
    requester = TestSupport::FakeRequester.new([json_response({events: []})])
    @client = Exa::Client.new(api_key: "abc", requester: requester, base_url: "https://api.test")
    @resource = @client.events
    @requester = requester
  end

  def test_list_and_retrieve
    @resource.list(limit: 5)
    assert_equal "https://api.test/v0/events?limit=5", @requester.requests.last[:url].to_s

    @requester.push_responder(json_response({id: "evt_123"}))
    @resource.retrieve("evt_123")
    assert_equal "https://api.test/v0/events/evt_123", @requester.requests.last[:url].to_s
  end

  private

  def json_response(body)
    lambda do |_req|
      response = TestSupport::FakeResponse.new("200", {"content-type" => "application/json"})
      [200, response, [body.to_json].each]
    end
  end
end
