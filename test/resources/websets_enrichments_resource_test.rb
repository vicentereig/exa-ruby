# frozen_string_literal: true

require "test_helper"

class WebsetsEnrichmentsResourceTest < Minitest::Test
  def setup
    requester = TestSupport::FakeRequester.new([])
    @client = Exa::Client.new(api_key: "abc", requester: requester, base_url: "https://api.test")
    @resource = @client.websets.enrichments
    @requester = requester
  end

  def test_create_and_retrieve
    @requester.push_responder(json_response(enrichment_payload))
    created = @resource.create("ws_123", description: "Company revenue", format: "text")
    assert_kind_of Exa::Responses::WebsetEnrichment, created
    assert_equal "https://api.test/v0/websets/ws_123/enrichments", @requester.requests.last[:url].to_s

    @requester.push_responder(json_response(enrichment_payload(status: "completed")))
    retrieved = @resource.retrieve("ws_123", "enr_1")
    assert_equal "completed", retrieved.status
  end

  def test_update_delete_cancel
    @requester.push_responder(json_response(enrichment_payload(title: "Updated")))
    @resource.update("ws_123", "enr_1", description: "Updated")
    assert_equal :patch, @requester.requests.last[:method]

    @requester.push_responder(json_response(enrichment_payload(status: "deleted")))
    @resource.delete("ws_123", "enr_1")
    assert_equal :delete, @requester.requests.last[:method]

    @requester.push_responder(json_response(enrichment_payload(status: "canceled")))
    @resource.cancel("ws_123", "enr_1")
    request = @requester.requests.last
    assert_equal :post, request[:method]
    assert_equal "https://api.test/v0/websets/ws_123/enrichments/enr_1/cancel", request[:url].to_s
  end

  private

  def enrichment_payload(overrides = {})
    {
      id: "enr_1",
      object: "webset_enrichment",
      status: "pending",
      websetId: "ws_123",
      title: "Revenue",
      description: "Company revenue information",
      format: "text",
      options: [{label: "Option A"}],
      metadata: {"env" => "test"},
      createdAt: "2024-01-01T00:00:00Z",
      updatedAt: "2024-01-01T00:00:00Z"
    }.merge(overrides)
  end

  def json_response(body)
    lambda do |_req|
      response = TestSupport::FakeResponse.new("200", {"content-type" => "application/json"})
      [200, response, [body.to_json].each]
    end
  end
end
