# frozen_string_literal: true

require "sorbet-runtime"

require_relative "exa/version"
require_relative "exa/errors"
require_relative "exa/internal/util"
require_relative "exa/internal/transport/pooled_net_requester"
require_relative "exa/internal/transport/base_client"
require_relative "exa/internal/transport/stream"
require_relative "exa/client"
require_relative "exa/types"
require_relative "exa/responses"
require_relative "exa/resources"
require_relative "exa/instrumentation"

module Exa
  class << self
    # Returns the global instrumentation event registry.
    # Use this to subscribe to API events for cost tracking, logging, etc.
    #
    # @example Subscribe to all request events
    #   Exa.instrumentation.subscribe('exa.request.*') do |event_name, payload|
    #     puts "#{event_name}: #{payload.inspect}"
    #   end
    #
    # @return [Exa::Instrumentation::EventRegistry]
    def instrumentation
      @instrumentation ||= Instrumentation::EventRegistry.new
    end

    # Emit an event to all subscribers.
    # Primarily used internally by the transport layer.
    #
    # @param event_name [String] The event name (e.g., 'exa.request.complete')
    # @param payload [Object] The event payload
    def emit(event_name, payload)
      instrumentation.notify(event_name, payload)
    end
  end
end
