# frozen_string_literal: true

require "test_helper"
require "json"
require_relative "cli_test_helper"

class ResearchCommandsTest < Minitest::Test
  include CliTestHelper

  def setup
    setup_cli_config
  end

  def teardown
    teardown_cli_config
  end

  def test_research_create_uses_instructions
    research = sample_research
    resource = RecordingResearchResource.new(create_response: research)
    fake_client = build_client(research: resource)

    Exa::Client.stub(:new, fake_client) do
      stdout, _stderr = capture_io do
        Exa::CLI::Root.start(
          ["research:create", "--instructions", "Map labs", "--json", "--config", cli_config_path]
        )
      end

      body = JSON.parse(stdout)
      assert_equal "res_123", body["id"]
      assert_equal({ instructions: "Map labs" }, resource.last_create_params)
    end
  end

  def test_research_list_passes_filters
    research = sample_research
    list_response = Exa::Responses::ResearchListResponse.new(
      data: [research],
      has_more: false,
      next_cursor: nil
    )
    resource = RecordingResearchResource.new(list_response: list_response)
    fake_client = build_client(research: resource)

    Exa::Client.stub(:new, fake_client) do
      stdout, _stderr = capture_io do
        Exa::CLI::Root.start(
          ["research:list", "--status", "running", "--cursor", "abc", "--limit", "5", "--json", "--config", cli_config_path]
        )
      end

      body = JSON.parse(stdout)
      assert_equal 1, body["data"].length
      assert_equal({ status: "running", cursor: "abc", limit: 5 }, resource.last_list_params)
    end
  end

  private

  def sample_research
    Exa::Responses::Research.new(
      id: "res_123",
      model: "exa-large",
      instructions: "Map labs",
      status: "running",
      created_at: 0,
      events: [],
      operations: [],
      output: nil,
      error: nil,
      raw: {}
    )
  end

  def build_client(research:)
    Struct.new(:search, :research, :websets, :events, :webhooks, :imports)
          .new(nil, research, nil, nil, nil, nil)
  end

  class RecordingResearchResource
    attr_reader :last_create_params, :last_list_params

    def initialize(create_response: nil, list_response: nil)
      @create_response = create_response
      @list_response = list_response
    end

    def create(params)
      @last_create_params = params
      @create_response
    end

    def list(params = nil)
      @last_list_params = params
      @list_response
    end
  end
end
