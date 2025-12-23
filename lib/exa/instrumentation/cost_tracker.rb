# frozen_string_literal: true

module Exa
  module Instrumentation
    # Built-in subscriber for tracking API costs from actual response data.
    # Thread-safe and works with both sync and async requests.
    #
    # @example Basic usage
    #   tracker = Exa::Instrumentation::CostTracker.new
    #   tracker.subscribe
    #
    #   client.search.search(query: "AI papers", num_results: 10)
    #   client.search.contents(urls: ["https://example.com"], text: true)
    #
    #   puts tracker.total_cost  # => 0.006
    #   puts tracker.summary     # => { Search => 0.005, Contents => 0.001 }
    #
    #   tracker.unsubscribe  # Clean up when done
    class CostTracker < BaseSubscriber
      # @return [Float] Total accumulated cost in dollars
      attr_reader :total_cost

      # @return [Integer] Number of requests tracked
      attr_reader :request_count

      # @return [Array<Hash>] All tracked requests with their costs
      attr_reader :requests

      def initialize
        @total_cost = 0.0
        @request_count = 0
        @requests = []
        @mutex = Mutex.new
        super()
      end

      # Subscribe to request completion events.
      # Call this after initialization to start tracking.
      def subscribe
        add_subscription("exa.request.complete") do |_event_name, payload|
          next unless payload.cost_dollars

          @mutex.synchronize do
            @total_cost += payload.cost_dollars
            @request_count += 1
            @requests << {
              endpoint: payload.endpoint,
              cost: payload.cost_dollars,
              request_id: payload.request_id,
              timestamp: payload.timestamp
            }
          end
        end
      end

      # Returns a summary of costs grouped by endpoint.
      # @return [Hash<Endpoint, Float>] Cost per endpoint
      def summary
        @mutex.synchronize do
          @requests
            .group_by { |req| req[:endpoint] }
            .transform_values { |reqs| reqs.sum { |r| r[:cost] } }
        end
      end

      # Returns the average cost per request.
      # @return [Float] Average cost or 0.0 if no requests
      def average_cost
        @mutex.synchronize do
          return 0.0 if @request_count.zero?
          @total_cost / @request_count
        end
      end

      # Reset all tracked data.
      def reset!
        @mutex.synchronize do
          @total_cost = 0.0
          @request_count = 0
          @requests.clear
        end
      end

      # Returns a formatted report of costs.
      # @return [String] Human-readable cost report
      def report
        @mutex.synchronize do
          lines = ["Exa API Cost Report"]
          lines << "-" * 40
          lines << "Total Cost: $#{format('%.6f', @total_cost)}"
          lines << "Request Count: #{@request_count}"
          lines << "Average Cost: $#{format('%.6f', @request_count.zero? ? 0.0 : @total_cost / @request_count)}"
          lines << ""
          lines << "By Endpoint:"

          @requests
            .group_by { |req| req[:endpoint] }
            .transform_values { |reqs| reqs.sum { |r| r[:cost] } }
            .sort_by { |_endpoint, cost| -cost }
            .each do |endpoint, cost|
              lines << "  #{endpoint.serialize}: $#{format('%.6f', cost)}"
            end

          lines.join("\n")
        end
      end
    end
  end
end
