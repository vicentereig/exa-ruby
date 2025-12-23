# frozen_string_literal: true

require_relative "../test_helper"

class EventRegistryTest < Minitest::Test
  def setup
    @registry = Exa::Instrumentation::EventRegistry.new
  end

  def test_subscribe_returns_subscription_id
    id = @registry.subscribe("test.event") { |_name, _payload| }
    assert_instance_of String, id
    refute_empty id
  end

  def test_subscribe_without_block_returns_nil
    id = @registry.subscribe("test.event")
    assert_nil id
  end

  def test_notify_calls_exact_match_subscribers
    received = []
    @registry.subscribe("test.event") { |name, payload| received << [name, payload] }

    @registry.notify("test.event", {foo: "bar"})

    assert_equal 1, received.length
    assert_equal ["test.event", {foo: "bar"}], received.first
  end

  def test_notify_does_not_call_non_matching_subscribers
    received = []
    @registry.subscribe("other.event") { |name, payload| received << [name, payload] }

    @registry.notify("test.event", {foo: "bar"})

    assert_empty received
  end

  def test_wildcard_pattern_matching
    received = []
    @registry.subscribe("exa.request.*") { |name, payload| received << name }

    @registry.notify("exa.request.start", {})
    @registry.notify("exa.request.complete", {})
    @registry.notify("exa.other.event", {})

    assert_equal 2, received.length
    assert_includes received, "exa.request.start"
    assert_includes received, "exa.request.complete"
  end

  def test_wildcard_at_end_matches_all_suffixes
    received = []
    @registry.subscribe("test.*") { |name, _| received << name }

    @registry.notify("test.one", {})
    @registry.notify("test.two.three", {})
    @registry.notify("other.test", {})

    assert_equal 2, received.length
    assert_includes received, "test.one"
    assert_includes received, "test.two.three"
  end

  def test_unsubscribe_removes_listener
    received = []
    id = @registry.subscribe("test.event") { |_name, _payload| received << true }

    @registry.notify("test.event", {})
    assert_equal 1, received.length

    @registry.unsubscribe(id)
    @registry.notify("test.event", {})
    assert_equal 1, received.length
  end

  def test_clear_listeners_removes_all
    @registry.subscribe("test.one") { }
    @registry.subscribe("test.two") { }

    assert_equal 2, @registry.listener_count

    @registry.clear_listeners

    assert_equal 0, @registry.listener_count
  end

  def test_listener_count
    assert_equal 0, @registry.listener_count

    @registry.subscribe("test.event") { }
    assert_equal 1, @registry.listener_count

    @registry.subscribe("test.other") { }
    assert_equal 2, @registry.listener_count
  end

  def test_multiple_subscribers_to_same_pattern
    received = []
    @registry.subscribe("test.event") { |_, p| received << "sub1" }
    @registry.subscribe("test.event") { |_, p| received << "sub2" }

    @registry.notify("test.event", {})

    assert_equal 2, received.length
    assert_includes received, "sub1"
    assert_includes received, "sub2"
  end

  def test_subscriber_error_does_not_break_other_subscribers
    received = []
    @registry.subscribe("test.event") { raise "Oops!" }
    @registry.subscribe("test.event") { |_, p| received << "success" }

    @registry.notify("test.event", {})

    assert_equal 1, received.length
    assert_includes received, "success"
  end
end
