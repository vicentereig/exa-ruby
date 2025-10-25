# frozen_string_literal: true

require "test_helper"

class SearchResourceTest < Minitest::Test
  def setup
    @responses = [json_response({results: []})]
    requester = TestSupport::FakeRequester.new(@responses)
    @client = Exa::Client.new(api_key: "abc", requester: requester, base_url: "https://api.test")
    @resource = @client.search
    @requester = requester
  end

  def test_search_serializes_params
    @resource.search(query: "ai", num_results: 3)
    request = @requester.requests.last
    assert_equal :post, request[:method]
    assert_equal "https://api.test/search", request[:url].to_s
    assert_equal({"query" => "ai", "numResults" => 3}, JSON.parse(request[:body]))
  end

  def test_contents_endpoint
    @resource.contents(urls: ["https://example.com"], text: true)
    request = @requester.requests.last
    assert_equal "https://api.test/contents", request[:url].to_s
  end

  def test_find_similar_endpoint
    @resource.find_similar(url: "https://example.com")
    request = @requester.requests.last
    assert_equal "https://api.test/findSimilar", request[:url].to_s
  end

  def test_answer_endpoint_merges_query
    @resource.answer(query: "Who funds frontier labs?", search_options: {num_results: 2})
    request = @requester.requests.last
    payload = JSON.parse(request[:body])
    assert_equal "Who funds frontier labs?", payload["query"]
    assert_equal "Who funds frontier labs?", payload.dig("searchOptions", "query")
  end

  private

  def json_response(body)
    lambda do |_req|
      response = TestSupport::FakeResponse.new("200", {"content-type" => "application/json"})
      [200, response, [body.to_json].each]
    end
  end
end
