# frozen_string_literal: true

require "test_helper"

class ResearchResourceTest < Minitest::Test
  def setup
    @responses = [json_response({id: "r_123"})]
    requester = TestSupport::FakeRequester.new(@responses)
    @client = Exa::Client.new(api_key: "abc", requester: requester, base_url: "https://api.test")
    @resource = @client.research
    @requester = requester
  end

  def test_create_serializes_params
    @resource.create(instructions: "Map labs")
    request = @requester.requests.last
    assert_equal "https://api.test/research", request[:url].to_s
    payload = JSON.parse(request[:body])
    assert_equal "Map labs", payload["instructions"]
  end

  def test_get_stream_true
    @responses << sse_response(["event:data\n", "data:{}\n\n"])
    @resource.get("r_123", stream: true)
    request = @requester.requests.last
    assert_equal "https://api.test/research/r_123?stream=true", request[:url].to_s
  end

  def test_list_passes_query
    @resource.list({limit: 10})
    request = @requester.requests.last
    assert_equal "https://api.test/research?limit=10", request[:url].to_s
  end

  def test_cancel
    @resource.cancel("r_123")
    request = @requester.requests.last
    assert_equal :post, request[:method]
    assert_equal "https://api.test/research/r_123/cancel", request[:url].to_s
  end

  private

  def json_response(body)
    lambda do |_req|
      response = TestSupport::FakeResponse.new("200", {"content-type" => "application/json"})
      [200, response, [body.to_json].each]
    end
  end

  def sse_response(events)
    lambda do |_req|
      response = TestSupport::FakeResponse.new("200", {"content-type" => "text/event-stream"})
      [200, response, events.each]
    end
  end
end
