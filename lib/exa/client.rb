# frozen_string_literal: true

module Exa
  class Client < Exa::Internal::Transport::BaseClient
    DEFAULT_BASE_URL = "https://api.exa.ai"

    attr_reader :api_key, :search, :research, :websets, :events, :webhooks, :imports

    def initialize(
      api_key: ENV["EXA_API_KEY"],
      base_url: ENV["EXA_BASE_URL"] || DEFAULT_BASE_URL,
      **opts
    )
      raise Exa::Errors::ConfigurationError, "api_key is required" if api_key.nil? || api_key.empty?

      @api_key = api_key
      super(base_url: base_url, **opts)

      @search = Exa::Resources::Search.new(client: self)
      @research = Exa::Resources::Research.new(client: self)
      @websets = Exa::Resources::Websets.new(client: self)
      @events = Exa::Resources::Events.new(client: self)
      @webhooks = Exa::Resources::Webhooks.new(client: self)
      @imports = Exa::Resources::Imports.new(client: self)
    end

    private

    def auth_headers
      {"x-api-key" => api_key}
    end
  end
end
