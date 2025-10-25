# frozen_string_literal: true

require "test_helper"

class WebsetsItemsResourceTest < Minitest::Test
  def setup
    requester = TestSupport::FakeRequester.new([])
    @client = Exa::Client.new(api_key: "abc", requester: requester, base_url: "https://api.test")
    @resource = @client.websets.items
    @requester = requester
  end

  def test_list_items
    @requester.push_responder(json_response(list_payload))
    response = @resource.list("ws_123", limit: 5)
    assert_kind_of Exa::Responses::WebsetItemListResponse, response
    request = @requester.requests.last
    assert_equal "https://api.test/v0/websets/ws_123/items?limit=5", request[:url].to_s
  end

  def test_retrieve_item
    @requester.push_responder(json_response(item_payload))
    item = @resource.retrieve("ws_123", "item_1")
    assert_kind_of Exa::Responses::WebsetItem, item
    assert_equal "item_1", item.id
    assert_equal "https://api.test/v0/websets/ws_123/items/item_1", @requester.requests.last[:url].to_s
  end

  def test_delete_item
    @requester.push_responder(json_response(item_payload))
    @resource.delete("ws_123", "item_1")
    request = @requester.requests.last
    assert_equal :delete, request[:method]
    assert_equal "https://api.test/v0/websets/ws_123/items/item_1", request[:url].to_s
  end

  private

  def item_payload(overrides = {})
    {
      id: "item_1",
      object: "webset_item",
      source: "search",
      sourceId: "src_1",
      websetId: "ws_123",
      properties: {title: "Example"},
      evaluations: [],
      enrichments: [],
      createdAt: "2024-01-01T00:00:00Z",
      updatedAt: "2024-01-01T00:00:00Z"
    }.merge(overrides)
  end

  def list_payload
    {
      data: [item_payload],
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
