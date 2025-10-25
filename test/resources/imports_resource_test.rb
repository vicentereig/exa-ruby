# frozen_string_literal: true

require "test_helper"

class ImportsResourceTest < Minitest::Test
  def setup
    requester = TestSupport::FakeRequester.new(Array.new(10) { json_response({id: "imp_123"}) })
    @client = Exa::Client.new(api_key: "abc", requester: requester, base_url: "https://api.test")
    @resource = @client.imports
    @requester = requester
  end

  def test_crud_paths
    @resource.create(name: "Initial")
    assert_equal "https://api.test/v0/imports", @requester.requests.last[:url].to_s

    @resource.list(limit: 5)
    assert_equal "https://api.test/v0/imports?limit=5", @requester.requests.last[:url].to_s

    @resource.retrieve("imp_123")
    assert_equal "https://api.test/v0/imports/imp_123", @requester.requests.last[:url].to_s

    @resource.update("imp_123", name: "Updated")
    assert_equal :patch, @requester.requests.last[:method]
    assert_equal "https://api.test/v0/imports/imp_123", @requester.requests.last[:url].to_s

    @resource.delete("imp_123")
    assert_equal :delete, @requester.requests.last[:method]
    assert_equal "https://api.test/v0/imports/imp_123", @requester.requests.last[:url].to_s
  end

  private

  def json_response(body)
    lambda do |_req|
      response = TestSupport::FakeResponse.new("200", {"content-type" => "application/json"})
      [200, response, [body.to_json].each]
    end
  end
end
