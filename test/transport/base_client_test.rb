# frozen_string_literal: true

require "test_helper"

class BaseClientTest < Minitest::Test

  def build_client(responses)
    requester = TestSupport::FakeRequester.new(responses)
    client = Exa::Client.new(api_key: "abc", requester: requester, base_url: "https://api.test")
    [client, requester]
  end

  def json_response(status:, body:)
    lambda do |_req|
      response = TestSupport::FakeResponse.new(status.to_s, {"content-type" => "application/json"})
      [status, response, [body].each]
    end
  end

  def sse_response(events)
    lambda do |_req|
      response = TestSupport::FakeResponse.new("200", {"content-type" => "text/event-stream"})
      [200, response, events.each]
    end
  end

  def test_request_builds_headers_and_url
    client, requester = build_client([json_response(status: 200, body: {ok: true}.to_json)])
    result = client.request(method: :get, path: "search", query: {q: "ruby"})

    assert_equal({ok: true}, result)
    request = requester.requests.first
    assert_equal "https://api.test/search?q=ruby", request[:url].to_s
    assert_equal "abc", request[:headers]["x-api-key"]
  end

  def test_retries_on_server_error
    responses = [
      json_response(status: 500, body: {error: "bad"}.to_json),
      json_response(status: 200, body: {ok: true}.to_json)
    ]
    client, requester = build_client(responses)
    result = client.request(method: :get, path: "search")
    assert_equal({ok: true}, result)
    assert_equal 2, requester.requests.size
  end

  def test_stream_response
    events = ["event:message\n", "data:{\"id\":1}\n\n"]
    client, _requester = build_client([sse_response(events)])
    stream = client.request(method: :get, path: "research", stream: true)
    payloads = stream.map { _1 }
    refute_empty payloads
    assert_equal events, payloads
  end

  def test_raises_on_error_status
    client, _requester = build_client([json_response(status: 400, body: {error: "bad"}.to_json)])
    assert_raises(Exa::Errors::APIStatusError) do
      client.request(method: :get, path: "search")
    end
  end

  def test_path_normalization_with_arrays_and_slashes
    client, requester = build_client([json_response(status: 200, body: {ok: true}.to_json)])
    client.request(method: :get, path: ["/v1/", "/search"])
    request = requester.requests.first
    assert_equal "https://api.test/v1/search", request[:url].to_s
  end

  def test_headers_drop_nil_values
    client, requester = build_client([json_response(status: 200, body: {ok: true}.to_json)])
    client.request(method: :get, path: "search", headers: {"x-custom" => "1", "x-nil" => nil})
    request = requester.requests.first
    refute_includes request[:headers].keys, "x-nil"
    assert_equal "1", request[:headers]["x-custom"]
  end

  def test_client_exposes_requester
    client, requester = build_client([json_response(status: 200, body: {ok: true}.to_json)])
    assert_equal requester, client.requester
  end

  def test_request_options_override_timeout_and_idempotency
    client, requester = build_client([json_response(status: 200, body: {ok: true}.to_json)])
    Process.stub(:clock_gettime, 1000.0) do
      client.request(
        method: :post,
        path: "search",
        request_options: {timeout: 5, idempotency_key: "abc-123"}
      )
    end
    request = requester.requests.last
    assert_in_delta 1005.0, request[:deadline], 0.0001
    assert_equal "abc-123", request[:headers]["idempotency-key"]
  end

  def test_request_options_limit_max_retries
    responses = [
      json_response(status: 500, body: {error: "bad"}.to_json),
      json_response(status: 200, body: {ok: true}.to_json)
    ]
    client, requester = build_client(responses)
    assert_raises(Exa::Errors::APIStatusError) do
      client.request(method: :get, path: "search", request_options: {max_retries: 0})
    end
    assert_equal 1, requester.requests.size
  end

  def test_retry_after_header_respected
    failing_lambda = lambda do |_req|
      response = TestSupport::FakeResponse.new("429", {"content-type" => "application/json", "retry-after" => "2"})
      [429, response, [{error: "busy"}.to_json].each]
    end
    responses = [
      failing_lambda,
      json_response(status: 200, body: {ok: true}.to_json)
    ]
    client, _requester = build_client(responses)
    sleeps = []
    client.stub(:sleep, ->(value) { sleeps << value }) do
      result = client.request(method: :get, path: "search")
      assert_equal({ok: true}, result)
    end
    assert_equal [2.0], sleeps
  end
end
