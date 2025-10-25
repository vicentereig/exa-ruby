# frozen_string_literal: true

require "test_helper"

class WebsetsResourceTest < Minitest::Test
  def setup
    @responses = Array.new(5) { json_response({id: "ws_123"}) }
    requester = TestSupport::FakeRequester.new(@responses)
    @client = Exa::Client.new(api_key: "abc", requester: requester, base_url: "https://api.test")
    @resource = @client.websets
    @requester = requester
  end

  def test_create
    @resource.create(name: "My Webset")
    request = @requester.requests.last
    assert_equal "https://api.test/websets", request[:url].to_s
    assert_equal({"name" => "My Webset"}, JSON.parse(request[:body]))
  end

  def test_list
    @resource.list(limit: 5)
    request = @requester.requests.last
    assert_equal "https://api.test/websets?limit=5", request[:url].to_s
  end

  def test_retrieve_update_delete
    @resource.retrieve("ws_123")
    assert_equal "https://api.test/websets/ws_123", @requester.requests.last[:url].to_s

    @resource.update("ws_123", name: "Updated")
    assert_equal :patch, @requester.requests.last[:method]

    @resource.delete("ws_123")
    assert_equal :delete, @requester.requests.last[:method]
  end

  private

  def json_response(body)
    lambda do |_req|
      response = TestSupport::FakeResponse.new("200", {"content-type" => "application/json"})
      [200, response, [body.to_json].each]
    end
  end
end
