# frozen_string_literal: true

require "test_helper"
require "json"
require_relative "cli_test_helper"

class WebhooksCommandsTest < Minitest::Test
  include CliTestHelper

  def setup
    setup_cli_config
  end

  def teardown
    teardown_cli_config
  end

  def test_webhooks_list_outputs_data
    webhook = sample_webhook
    list_response = Exa::Responses::WebhookListResponse.new(
      data: [webhook],
      has_more: false,
      next_cursor: nil
    )
    resource = RecordingWebhooksResource.new(list_response: list_response)
    fake_client = build_client(webhooks: resource)

    Exa::Client.stub(:new, fake_client) do
      stdout, _stderr = capture_io do
        Exa::CLI::Root.start(["webhooks:list", "--json", "--config", cli_config_path])
      end

      data = JSON.parse(stdout)
      assert_equal 1, data["data"].length
      assert resource.list_called
    end
  end

  def test_webhooks_attempts_accepts_filters
    attempts = Exa::Responses::WebhookAttemptListResponse.new(
      data: [sample_attempt],
      has_more: false,
      next_cursor: nil
    )
    resource = RecordingWebhooksResource.new(attempts_response: attempts)
    fake_client = build_client(webhooks: resource)

    Exa::Client.stub(:new, fake_client) do
      stdout, _stderr = capture_io do
        Exa::CLI::Root.start(
          ["webhooks:attempts", "wh_123", "--cursor", "abc", "--limit", "20", "--json", "--config", cli_config_path]
        )
      end

      data = JSON.parse(stdout)
      assert_equal 1, data["data"].length
      assert_equal({ cursor: "abc", limit: 20 }, resource.last_attempts_params)
    end
  end

  private

  def sample_webhook
    Exa::Responses::Webhook.new(
      id: "wh_123",
      object: "webhook",
      status: "active",
      events: ["webset.created"],
      url: "https://example.com",
      secret: "secret",
      metadata: {},
      created_at: nil,
      updated_at: nil
    )
  end

  def sample_attempt
    Exa::Responses::WebhookAttempt.new(
      id: "attempt_123",
      object: "webhook.attempt",
      event_id: "evt_123",
      event_type: "webset.created",
      webhook_id: "wh_123",
      url: "https://example.com",
      successful: true,
      response_headers: {},
      response_body: nil,
      response_status_code: 200,
      attempt: 1,
      attempted_at: nil
    )
  end

  def build_client(webhooks:)
    Struct.new(:search, :research, :websets, :events, :webhooks, :imports)
          .new(nil, nil, nil, nil, webhooks, nil)
  end

  class RecordingWebhooksResource
    attr_reader :last_attempts_params, :list_called

    def initialize(list_response: nil, attempts_response: nil)
      @list_response = list_response
      @attempts_response = attempts_response
    end

    def list(_params = nil)
      @list_called = true
      @list_response
    end

    def attempts(id, params = nil)
      @last_attempts_params = params
      @attempts_response
    end
  end
end
