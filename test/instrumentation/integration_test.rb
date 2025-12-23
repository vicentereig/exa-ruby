# frozen_string_literal: true

require_relative "../test_helper"

class InstrumentationIntegrationTest < Minitest::Test
  def setup
    Exa.instrumentation.clear_listeners
    @events = []
    @subscription_id = Exa.instrumentation.subscribe("exa.request.*") do |name, payload|
      @events << {name: name, payload: payload}
    end
  end

  def teardown
    Exa.instrumentation.unsubscribe(@subscription_id)
    Exa.instrumentation.clear_listeners
  end

  def test_search_request_emits_start_and_complete_events
    requester = TestSupport::FakeRequester.new([])
    requester.push_responder(json_response({
      "requestId" => "req_123",
      "results" => [],
      "costDollars" => {"total" => 0.005}
    }))

    client = Exa::Client.new(api_key: "test-key", requester: requester, base_url: "https://api.test")
    client.search.search(query: "test query", num_results: 10)

    assert_equal 2, @events.length

    start_event = @events.find { |e| e[:name] == "exa.request.start" }
    complete_event = @events.find { |e| e[:name] == "exa.request.complete" }

    refute_nil start_event
    refute_nil complete_event

    assert_equal Exa::Instrumentation::Endpoint::Search, start_event[:payload].endpoint
    assert_equal :post, start_event[:payload].http_method
    assert_equal "search", start_event[:payload].path

    assert_equal Exa::Instrumentation::Endpoint::Search, complete_event[:payload].endpoint
    assert_equal 200, complete_event[:payload].status
    assert_equal 0.005, complete_event[:payload].cost_dollars
    assert complete_event[:payload].duration_ms > 0
  end

  def test_contents_request_emits_events
    requester = TestSupport::FakeRequester.new([])
    requester.push_responder(json_response({
      "requestId" => "req_456",
      "results" => [],
      "costDollars" => {"total" => 0.003}
    }))

    client = Exa::Client.new(api_key: "test-key", requester: requester, base_url: "https://api.test")
    client.search.contents(urls: ["https://example.com"])

    assert_equal 2, @events.length

    complete_event = @events.find { |e| e[:name] == "exa.request.complete" }
    assert_equal Exa::Instrumentation::Endpoint::Contents, complete_event[:payload].endpoint
    assert_equal 0.003, complete_event[:payload].cost_dollars
  end

  def test_request_error_emits_error_event
    requester = TestSupport::FakeRequester.new([])
    requester.push_responder(error_response(401, {"error" => "Unauthorized"}))

    client = Exa::Client.new(api_key: "test-key", requester: requester, base_url: "https://api.test")

    assert_raises(Exa::Errors::APIStatusError) do
      client.search.search(query: "test")
    end

    error_event = @events.find { |e| e[:name] == "exa.request.error" }
    refute_nil error_event
    assert_equal Exa::Instrumentation::Endpoint::Search, error_event[:payload].endpoint
    assert_includes error_event[:payload].error_class, "APIStatusError"
    assert error_event[:payload].duration_ms > 0
  end

  def test_cost_tracker_integration
    Exa.instrumentation.clear_listeners

    tracker = Exa::Instrumentation::CostTracker.new
    tracker.subscribe

    requester = TestSupport::FakeRequester.new([])
    requester.push_responder(json_response({
      "requestId" => "req_789",
      "results" => [],
      "costDollars" => {"total" => 0.005}
    }))

    client = Exa::Client.new(api_key: "test-key", requester: requester, base_url: "https://api.test")
    client.search.search(query: "test query")

    assert_equal 0.005, tracker.total_cost
    assert_equal 1, tracker.request_count

    # Second request
    requester2 = TestSupport::FakeRequester.new([])
    requester2.push_responder(json_response({
      "requestId" => "req_790",
      "results" => [],
      "costDollars" => {"total" => 0.003}
    }))

    client2 = Exa::Client.new(api_key: "test-key", requester: requester2, base_url: "https://api.test")
    client2.search.contents(urls: ["https://example.com"])

    assert_in_delta 0.008, tracker.total_cost, 0.0001
    assert_equal 2, tracker.request_count

    summary = tracker.summary
    assert_equal 0.005, summary[Exa::Instrumentation::Endpoint::Search]
    assert_equal 0.003, summary[Exa::Instrumentation::Endpoint::Contents]

    tracker.unsubscribe
  end

  def test_endpoint_detection_for_various_paths
    # Test endpoint detection directly
    assert_equal Exa::Instrumentation::Endpoint::Search,
                 Exa::Instrumentation::Endpoint.from_path("search")
    assert_equal Exa::Instrumentation::Endpoint::Contents,
                 Exa::Instrumentation::Endpoint.from_path("contents")
    assert_equal Exa::Instrumentation::Endpoint::FindSimilar,
                 Exa::Instrumentation::Endpoint.from_path("findSimilar")
    assert_equal Exa::Instrumentation::Endpoint::Answer,
                 Exa::Instrumentation::Endpoint.from_path("answer")
    assert_equal Exa::Instrumentation::Endpoint::Research,
                 Exa::Instrumentation::Endpoint.from_path("research")
    assert_equal Exa::Instrumentation::Endpoint::Research,
                 Exa::Instrumentation::Endpoint.from_path("research/abc123")
    assert_equal Exa::Instrumentation::Endpoint::ResearchCancel,
                 Exa::Instrumentation::Endpoint.from_path("research/abc123/cancel")
  end

  private

  def json_response(body)
    lambda do |_req|
      response = TestSupport::FakeResponse.new("200", {"content-type" => "application/json"})
      [200, response, [body.to_json].each]
    end
  end

  def error_response(status, body)
    lambda do |_req|
      response = TestSupport::FakeResponse.new(status.to_s, {"content-type" => "application/json"})
      [status, response, [body.to_json].each]
    end
  end
end
