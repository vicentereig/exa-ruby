# frozen_string_literal: true

require "securerandom"

module Exa
  module Instrumentation
    # Thread-safe event registry for subscribing to and emitting API events.
    # Supports wildcard pattern matching (e.g., 'exa.request.*').
    class EventRegistry
      def initialize
        @listeners = {}
        @mutex = Mutex.new
      end

      # Subscribe to events matching a pattern.
      # @param pattern [String] Event pattern (supports '*' wildcard)
      # @yield [event_name, payload] Block called when matching events are emitted
      # @return [String] Subscription ID for later unsubscription
      def subscribe(pattern, &block)
        return unless block_given?

        subscription_id = SecureRandom.uuid
        @mutex.synchronize do
          @listeners[subscription_id] = {
            pattern: pattern,
            block: block
          }
        end

        subscription_id
      end

      # Unsubscribe from events.
      # @param subscription_id [String] The ID returned from subscribe
      def unsubscribe(subscription_id)
        @mutex.synchronize do
          @listeners.delete(subscription_id)
        end
      end

      # Clear all listeners.
      def clear_listeners
        @mutex.synchronize do
          @listeners.clear
        end
      end

      # Emit an event to all matching subscribers.
      # @param event_name [String] The event name (e.g., 'exa.request.complete')
      # @param payload [Object] The event payload (usually a typed struct)
      def notify(event_name, payload)
        # Take a snapshot of current listeners to avoid holding the mutex during execution
        matching_listeners = @mutex.synchronize do
          @listeners.select do |_id, listener|
            pattern_matches?(listener[:pattern], event_name)
          end.dup
        end

        matching_listeners.each do |_id, listener|
          listener[:block].call(event_name, payload)
        rescue StandardError
          # Silently ignore listener errors to avoid breaking the main flow
        end
      end

      # Returns the count of registered listeners.
      def listener_count
        @mutex.synchronize { @listeners.size }
      end

      private

      def pattern_matches?(pattern, event_name)
        if pattern.include?("*")
          # Convert wildcard pattern to regex
          # exa.request.* becomes ^exa\.request\..*$
          regex_pattern = "^#{Regexp.escape(pattern).gsub('\\*', '.*')}$"
          Regexp.new(regex_pattern).match?(event_name)
        else
          # Exact match
          pattern == event_name
        end
      end
    end

    # Base class for creating event subscribers.
    # Subclasses should implement #subscribe to add subscriptions.
    #
    # @example
    #   class MyCostTracker < Exa::Instrumentation::BaseSubscriber
    #     def initialize
    #       @total = 0.0
    #       super()
    #     end
    #
    #     def subscribe
    #       add_subscription('exa.request.complete') do |_, payload|
    #         @total += payload.cost_dollars || 0
    #       end
    #     end
    #   end
    class BaseSubscriber
      def initialize
        @subscriptions = []
      end

      # Override to add subscriptions. Called automatically after initialize.
      def subscribe
        raise NotImplementedError, "Subclasses must implement #subscribe"
      end

      # Unsubscribe from all registered subscriptions.
      def unsubscribe
        @subscriptions.each { |id| Exa.instrumentation.unsubscribe(id) }
        @subscriptions.clear
      end

      protected

      # Add a subscription to the global event registry.
      # @param pattern [String] Event pattern to match
      # @yield [event_name, payload] Block called for matching events
      # @return [String] Subscription ID
      def add_subscription(pattern, &block)
        subscription_id = Exa.instrumentation.subscribe(pattern, &block)
        @subscriptions << subscription_id
        subscription_id
      end
    end
  end
end

require_relative "instrumentation/events"
require_relative "instrumentation/cost_tracker"
