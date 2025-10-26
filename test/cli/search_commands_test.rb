# frozen_string_literal: true

require "test_helper"
require "json"
require_relative "cli_test_helper"

class SearchCommandsTest < Minitest::Test
  include CliTestHelper

  def setup
    setup_cli_config
  end

  def teardown
    teardown_cli_config
  end

  def test_search_run_passes_parameters_and_renders_json
    fake_result = build_result("Doc 1", "https://example.com")
    fake_response = Exa::Responses::SearchResponse.new(
      request_id: "req_123",
      resolved_search_type: nil,
      search_type: nil,
      results: [fake_result],
      context: nil,
      cost_dollars: nil
    )

    resource = RecordingSearchResource.new(search_response: fake_response)
    fake_client = Struct.new(:search).new(resource)

    Exa::Client.stub(:new, fake_client) do
      stdout, _stderr = capture_io do
        Exa::CLI::Root.start(["search:run", "latest llms", "--num-results", "5", "--json", "--config", cli_config_path])
      end

      data = JSON.parse(stdout)
      assert_equal "req_123", data["request_id"]
      assert_equal "https://example.com", data["results"].first["url"]
    end

    assert_equal({ query: "latest llms", num_results: 5 }, resource.last_search_params)
  end

  def test_search_contents_uses_urls_flag
    fake_result = build_result("Exa", "https://exa.ai")
    fake_response = Exa::Responses::ContentsResponse.new(
      request_id: "req_contents",
      results: [fake_result],
      context: nil,
      statuses: nil,
      cost_dollars: nil
    )

    resource = RecordingSearchResource.new(search_response: nil, contents_response: fake_response)
    fake_client = Struct.new(:search).new(resource)

    Exa::Client.stub(:new, fake_client) do
      stdout, _stderr = capture_io do
        Exa::CLI::Root.start(["search:contents", "--urls", "https://exa.ai", "--json", "--config", cli_config_path])
      end

      data = JSON.parse(stdout)
      assert_equal "req_contents", data["request_id"]
      assert_equal "Exa", data["results"].first["title"]
    end

    assert_equal({ urls: ["https://exa.ai"] }, resource.last_contents_params)
  end

  def test_search_run_outputs_jsonl_format
    fake_result = build_result("Doc 1", "https://example.com")
    fake_response = Exa::Responses::SearchResponse.new(
      request_id: "req_jsonl",
      resolved_search_type: nil,
      search_type: nil,
      results: [fake_result],
      context: nil,
      cost_dollars: nil
    )
    resource = RecordingSearchResource.new(search_response: fake_response)
    fake_client = Struct.new(:search).new(resource)

    Exa::Client.stub(:new, fake_client) do
      stdout, _stderr = capture_io do
        Exa::CLI::Root.start(
          ["search:run", "latest llms", "--format", "jsonl", "--config", cli_config_path]
        )
      end

      lines = stdout.strip.split("\n")
      assert_equal 1, lines.size
      data = JSON.parse(lines.first)
      assert_equal "Doc 1", data["title"]
    end
  end

  private

  def build_result(title, url)
    Exa::Responses::ResultWithContent.new(
      title: title,
      url: url,
      published_date: nil,
      author: nil,
      score: nil,
      id: nil,
      image: nil,
      favicon: nil,
      text: nil,
      highlights: nil,
      highlight_scores: nil,
      summary: nil,
      subpages: nil,
      extras: nil
    )
  end

  class RecordingSearchResource
    attr_reader :last_search_params, :last_contents_params

    def initialize(search_response:, contents_response: nil)
      @search_response = search_response
      @contents_response = contents_response
    end

    def search(params)
      @last_search_params = params
      @search_response
    end

    def contents(params)
      @last_contents_params = params
      @contents_response
    end
  end
end
