# frozen_string_literal: true

require "test_helper"

class WebsetsResourceTest < Minitest::Test
  def setup
    requester = TestSupport::FakeRequester.new([])
    @client = Exa::Client.new(api_key: "abc", requester: requester, base_url: "https://api.test")
    @resource = @client.websets
    @requester = requester
  end

  def test_create
    @requester.push_responder(json_response(webset_payload))
    response = @resource.create(name: "My Webset")
    assert_kind_of Exa::Responses::Webset, response
    request = @requester.requests.last
    assert_equal "https://api.test/v0/websets", request[:url].to_s
    assert_equal({"name" => "My Webset"}, JSON.parse(request[:body]))
  end

  def test_list
    @requester.push_responder(json_response(webset_list_payload))
    response = @resource.list(limit: 5)
    assert_kind_of Exa::Responses::WebsetListResponse, response
    request = @requester.requests.last
    assert_equal "https://api.test/v0/websets?limit=5", request[:url].to_s
  end

  def test_retrieve_update_delete
    @requester.push_responder(json_response(webset_payload))
    retrieved = @resource.retrieve("ws_123")
    assert_kind_of Exa::Responses::Webset, retrieved
    assert_equal "https://api.test/v0/websets/ws_123", @requester.requests.last[:url].to_s

    @requester.push_responder(json_response(webset_payload(title: "Updated")))
    updated = @resource.update("ws_123", name: "Updated")
    assert_kind_of Exa::Responses::Webset, updated
    assert_equal :patch, @requester.requests.last[:method]

    @requester.push_responder(json_response(webset_payload(status: "paused")))
    deleted = @resource.delete("ws_123")
    assert_kind_of Exa::Responses::Webset, deleted
    assert_equal :delete, @requester.requests.last[:method]
  end

  private

  def webset_payload(overrides = {})
    {
      id: "ws_123",
      object: "webset",
      status: "idle",
      externalId: "ext_1",
      title: "My Webset",
      searches: [],
      imports: [],
      enrichments: [],
      monitors: [],
      streams: [],
      metadata: {"env" => "test"},
      createdAt: "2024-01-01T00:00:00Z",
      updatedAt: "2024-01-01T00:00:00Z"
    }.merge(overrides)
  end

  def webset_list_payload
    {
      data: [webset_payload],
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
