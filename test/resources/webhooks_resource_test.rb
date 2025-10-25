# frozen_string_literal: true

require "test_helper"

class WebhooksResourceTest < Minitest::Test
  def setup
    requester = TestSupport::FakeRequester.new(Array.new(10) { json_response({id: "wh_123"}) })
    @client = Exa::Client.new(api_key: "abc", requester: requester, base_url: "https://api.test")
    @resource = @client.webhooks
    @requester = requester
  end

  def test_crud_paths
    @resource.create(url: "https://example.com")
    assert_equal "https://api.test/v0/webhooks", @requester.requests.last[:url].to_s

    @resource.list
    assert_equal "https://api.test/v0/webhooks", @requester.requests.last[:url].to_s

    @resource.retrieve("wh_123")
    assert_equal "https://api.test/v0/webhooks/wh_123", @requester.requests.last[:url].to_s

    @resource.update("wh_123", url: "https://new")
    assert_equal :patch, @requester.requests.last[:method]
    assert_equal "https://api.test/v0/webhooks/wh_123", @requester.requests.last[:url].to_s

    @resource.delete("wh_123")
    assert_equal :delete, @requester.requests.last[:method]
    assert_equal "https://api.test/v0/webhooks/wh_123", @requester.requests.last[:url].to_s
  end

  def test_attempts
    @resource.attempts("wh_123", limit: 2)
    assert_equal "https://api.test/v0/webhooks/wh_123/attempts?limit=2", @requester.requests.last[:url].to_s
  end

  private

  def json_response(body)
    lambda do |_req|
      response = TestSupport::FakeResponse.new("200", {"content-type" => "application/json"})
      [200, response, [body.to_json].each]
    end
  end
end
