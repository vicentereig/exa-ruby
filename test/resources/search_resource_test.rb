# frozen_string_literal: true

require "test_helper"

class SearchResourceTest < Minitest::Test
  def setup
    requester = TestSupport::FakeRequester.new([])
    @client = Exa::Client.new(api_key: "abc", requester: requester, base_url: "https://api.test")
    @resource = @client.search
    @requester = requester
  end

  def test_search_serializes_params
    @requester.push_responder(json_response({results: []}))
    response = @resource.search(query: "ai", num_results: 3)
    request = @requester.requests.last
    assert_equal :post, request[:method]
    assert_equal "https://api.test/search", request[:url].to_s
    assert_equal({"query" => "ai", "numResults" => 3}, JSON.parse(request[:body]))
    assert_kind_of Exa::Responses::SearchResponse, response
  end

  def test_contents_endpoint
    @requester.push_responder(json_response({results: []}))
    response = @resource.contents(urls: ["https://example.com"], text: true)
    request = @requester.requests.last
    assert_equal "https://api.test/contents", request[:url].to_s
    assert_kind_of Exa::Responses::ContentsResponse, response
  end

  def test_contents_parses_subpages_as_result_with_content
    response_with_subpages = {
      results: [{
        url: "https://example.com",
        id: "abc123",
        title: "Main Page",
        text: "Main content",
        subpages: [{
          url: "https://example.com/sub",
          id: "sub123",
          title: "Subpage",
          text: "Subpage content",
          highlights: ["important text"]
        }]
      }]
    }
    @requester.push_responder(json_response(response_with_subpages))
    response = @resource.contents(urls: ["https://example.com"], text: true, subpages: 1)

    result = response.results.first
    assert_equal 1, result.subpages.size

    subpage = result.subpages.first
    assert_kind_of Exa::Responses::ResultWithContent, subpage
    assert_equal "Subpage content", subpage.text
    assert_equal ["important text"], subpage.highlights
  end

  def test_find_similar_endpoint
    @requester.push_responder(json_response({results: []}))
    response = @resource.find_similar(url: "https://example.com")
    request = @requester.requests.last
    assert_equal "https://api.test/findSimilar", request[:url].to_s
    assert_kind_of Exa::Responses::FindSimilarResponse, response
  end

  def test_answer_endpoint_merges_query
    @requester.push_responder(json_response(answer_payload))
    @resource.answer(query: "Who funds frontier labs?", search_options: {num_results: 2})
    request = @requester.requests.last
    payload = JSON.parse(request[:body])
    assert_equal "Who funds frontier labs?", payload["query"]
    assert_equal "Who funds frontier labs?", payload.dig("searchOptions", "query")
  end

  def test_answer_returns_typed_response
    @requester.push_responder(json_response(answer_payload))
    resp = @resource.answer(query: "Latest robotics grants")
    assert_kind_of Exa::Responses::AnswerResponse, resp
    assert_equal "42", resp.answer
    assert_equal 1, resp.citations.size
  end

  def test_answer_stream_returns_stream_object
    events = ["data:{\"answer\":\"partial\"}\n\n"]
    @requester.push_responder(sse_response(events))
    stream = @resource.answer(query: "Streamed", stream: true)
    assert_kind_of Exa::Internal::Transport::Stream, stream
    payloads = []
    stream.each_event_json { |evt| payloads << evt[:data] }
    assert_equal [{answer: "partial"}], payloads
  end

  private

  def answer_payload
    {
      answer: "42",
      citations: [
        {
          id: "doc_1",
          url: "https://example.com",
          title: "Example"
        }
      ],
      costDollars: {total: 0.01}
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
