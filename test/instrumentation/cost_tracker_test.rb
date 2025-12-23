# frozen_string_literal: true

require_relative "../test_helper"

class CostTrackerTest < Minitest::Test
  def setup
    # Clear any existing listeners from previous tests
    Exa.instrumentation.clear_listeners
    @tracker = Exa::Instrumentation::CostTracker.new
    @tracker.subscribe
  end

  def teardown
    @tracker.unsubscribe
  end

  def test_initial_state
    assert_equal 0.0, @tracker.total_cost
    assert_equal 0, @tracker.request_count
    assert_empty @tracker.requests
  end

  def test_tracks_cost_from_request_complete_event
    emit_complete_event(cost_dollars: 0.005)

    assert_equal 0.005, @tracker.total_cost
    assert_equal 1, @tracker.request_count
    assert_equal 1, @tracker.requests.length
  end

  def test_ignores_events_without_cost
    emit_complete_event(cost_dollars: nil)

    assert_equal 0.0, @tracker.total_cost
    assert_equal 0, @tracker.request_count
    assert_empty @tracker.requests
  end

  def test_accumulates_costs_from_multiple_requests
    emit_complete_event(cost_dollars: 0.005)
    emit_complete_event(cost_dollars: 0.003)
    emit_complete_event(cost_dollars: 0.002)

    assert_in_delta 0.01, @tracker.total_cost, 0.0001
    assert_equal 3, @tracker.request_count
  end

  def test_summary_groups_by_endpoint
    emit_complete_event(cost_dollars: 0.005, endpoint: Exa::Instrumentation::Endpoint::Search)
    emit_complete_event(cost_dollars: 0.003, endpoint: Exa::Instrumentation::Endpoint::Contents)
    emit_complete_event(cost_dollars: 0.002, endpoint: Exa::Instrumentation::Endpoint::Search)

    summary = @tracker.summary

    assert_in_delta 0.007, summary[Exa::Instrumentation::Endpoint::Search], 0.0001
    assert_in_delta 0.003, summary[Exa::Instrumentation::Endpoint::Contents], 0.0001
  end

  def test_average_cost
    emit_complete_event(cost_dollars: 0.010)
    emit_complete_event(cost_dollars: 0.006)
    emit_complete_event(cost_dollars: 0.008)

    assert_in_delta 0.008, @tracker.average_cost, 0.0001
  end

  def test_average_cost_with_no_requests
    assert_equal 0.0, @tracker.average_cost
  end

  def test_reset_clears_all_data
    emit_complete_event(cost_dollars: 0.005)
    emit_complete_event(cost_dollars: 0.003)

    @tracker.reset!

    assert_equal 0.0, @tracker.total_cost
    assert_equal 0, @tracker.request_count
    assert_empty @tracker.requests
  end

  def test_report_generates_formatted_output
    emit_complete_event(cost_dollars: 0.005, endpoint: Exa::Instrumentation::Endpoint::Search)
    emit_complete_event(cost_dollars: 0.003, endpoint: Exa::Instrumentation::Endpoint::Contents)

    report = @tracker.report

    assert_includes report, "Exa API Cost Report"
    assert_includes report, "Total Cost: $0.008"
    assert_includes report, "Request Count: 2"
    assert_includes report, "By Endpoint:"
  end

  def test_unsubscribe_stops_tracking
    emit_complete_event(cost_dollars: 0.005)
    assert_equal 1, @tracker.request_count

    @tracker.unsubscribe

    emit_complete_event(cost_dollars: 0.003)
    assert_equal 1, @tracker.request_count
  end

  private

  def emit_complete_event(cost_dollars:, endpoint: Exa::Instrumentation::Endpoint::Search)
    Exa.emit(
      "exa.request.complete",
      Exa::Instrumentation::Events::RequestComplete.new(
        request_id: SecureRandom.uuid,
        endpoint: endpoint,
        duration_ms: 100.0,
        status: 200,
        cost_dollars: cost_dollars,
        timestamp: Process.clock_gettime(Process::CLOCK_MONOTONIC)
      )
    )
  end
end
