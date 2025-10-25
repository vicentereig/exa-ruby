# frozen_string_literal: true

require "test_helper"

class ResearchResourceTest < Minitest::Test
  def setup
    requester = TestSupport::FakeRequester.new([])
    @client = Exa::Client.new(api_key: "abc", requester: requester, base_url: "https://api.test")
    @resource = @client.research
    @requester = requester
  end

  def test_create_serializes_params
    @requester.push_responder(json_response(research_payload))
    @resource.create(instructions: "Map labs")
    request = @requester.requests.last
    assert_equal "https://api.test/research", request[:url].to_s
    payload = JSON.parse(request[:body])
    assert_equal "Map labs", payload["instructions"]
  end

  def test_get_stream_true
    @requester.push_responder(sse_response(["event:data\n", "data:{}\n\n"]))
    @resource.get("r_123", stream: true)
    request = @requester.requests.last
    assert_equal "https://api.test/research/r_123?stream=true", request[:url].to_s
  end

  def test_get_without_stream_returns_typed_response
    @requester.push_responder(json_response(research_payload))
    response = @resource.get("r_123")
    assert_kind_of Exa::Responses::Research, response
    assert_equal "r_123", response.id
  end

  def test_list_passes_query
    @requester.push_responder(json_response(research_list_payload))
    response = @resource.list({limit: 10})
    assert_kind_of Exa::Responses::ResearchListResponse, response
    request = @requester.requests.last
    assert_equal "https://api.test/research?limit=10", request[:url].to_s
  end

  def test_cancel
    @requester.push_responder(json_response(research_payload(status: "cancelled")))
    response = @resource.cancel("r_123")
    assert_kind_of Exa::Responses::Research, response
    request = @requester.requests.last
    assert_equal :post, request[:method]
    assert_equal "https://api.test/research/r_123/cancel", request[:url].to_s
  end

  private

  def research_payload(overrides = {})
    {
      researchId: "r_123",
      createdAt: 1_704_000_000_000,
      model: "exa-research",
      instructions: "Map labs",
      status: "running",
      events: [],
      operations: [],
      output: {content: "result"}
    }.merge(overrides)
  end

  def research_list_payload
    {
      data: [research_payload],
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

  def sse_response(events)
    lambda do |_req|
      response = TestSupport::FakeResponse.new("200", {"content-type" => "text/event-stream"})
      [200, response, events.each]
    end
  end
end
