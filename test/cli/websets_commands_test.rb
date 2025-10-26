# frozen_string_literal: true

require "test_helper"
require "json"
require_relative "cli_test_helper"

class WebsetsCommandsTest < Minitest::Test
  include CliTestHelper

  def setup
    setup_cli_config
  end

  def teardown
    teardown_cli_config
  end

  def test_websets_create_uses_json_payload
    webset = sample_webset
    resource = RecordingWebsetsResource.new(create_response: webset)
    fake_client = build_client(websets: resource)

    Exa::Client.stub(:new, fake_client) do
      stdout, _stderr = capture_io do
        Exa::CLI::Root.start(
          ["websets:create", "--data", '{"title":"List"}', "--json", "--config", cli_config_path]
        )
      end

      body = JSON.parse(stdout)
      assert_equal "webset_123", body["id"]
      assert_equal({"title" => "List"}, resource.last_create_payload)
    end
  end

  def test_webset_items_list_hits_nested_resource
    item = sample_item
    items_response = Exa::Responses::WebsetItemListResponse.new(
      data: [item],
      has_more: false,
      next_cursor: nil
    )
    resource = RecordingWebsetsResource.new(items_list_response: items_response)
    fake_client = build_client(websets: resource)

    Exa::Client.stub(:new, fake_client) do
      stdout, _stderr = capture_io do
        Exa::CLI::Root.start(
          ["websets:items:list", "webset_123", "--json", "--config", cli_config_path]
        )
      end

      body = JSON.parse(stdout)
      assert_equal 1, body["data"].length
      assert_equal ["webset_123", nil], resource.items_resource.last_list_args
    end
  end

  private

  def sample_webset
    Exa::Responses::Webset.new(
      id: "webset_123",
      object: "webset",
      status: "active",
      external_id: nil,
      title: "Example",
      searches: [],
      imports: [],
      enrichments: [],
      monitors: [],
      streams: [],
      metadata: {},
      created_at: nil,
      updated_at: nil,
      raw: {}
    )
  end

  def sample_item
    Exa::Responses::WebsetItem.new(
      id: "item_123",
      object: "webset.item",
      source: "search",
      source_id: "doc",
      webset_id: "webset_123",
      properties: {},
      evaluations: [],
      enrichments: [],
      created_at: nil,
      updated_at: nil,
      raw: {}
    )
  end

  def build_client(websets:)
    Struct.new(:search, :research, :websets, :events, :webhooks, :imports)
          .new(nil, nil, websets, nil, nil, nil)
  end

  class RecordingWebsetsResource
    attr_reader :last_create_payload, :items_resource

    def initialize(create_response: nil, items_list_response: nil)
      @create_response = create_response
      @items_resource = RecordingItemsResource.new(items_list_response)
    end

    def create(params)
      @last_create_payload = params
      @create_response
    end

    def items
      @items_resource
    end

    class RecordingItemsResource
      attr_reader :last_list_args

      def initialize(list_response)
        @list_response = list_response
      end

      def list(webset_id, params = nil)
        @last_list_args = [webset_id, params]
        @list_response
      end
    end
  end
end
