# frozen_string_literal: true

require "test_helper"

class WebsetsMonitorsResourceTest < Minitest::Test
  def setup
    @responses = Array.new(10) { json_response({id: "mon_123", status: "active"}) }
    requester = TestSupport::FakeRequester.new(@responses)
    @client = Exa::Client.new(api_key: "abc", requester: requester, base_url: "https://api.test")
    @resource = @client.websets.monitors
    @requester = requester
  end

  def test_create_monitor
    monitor = @resource.create(websetId: "ws_1", cadence: {type: "daily"})
    assert_kind_of Exa::Responses::Monitor, monitor
    request = @requester.requests.last
    assert_equal "https://api.test/monitors", request[:url].to_s
  end

  def test_list_monitors
    list = @resource.list(websetId: "ws_1")
    assert_kind_of Exa::Responses::MonitorListResponse, list
    assert_equal "https://api.test/monitors?websetId=ws_1", @requester.requests.last[:url].to_s
  end

  def test_runs_paths
    @resource.runs_list("mon_123")
    assert_equal "https://api.test/monitors/mon_123/runs", @requester.requests.last[:url].to_s

    @resource.runs_get("mon_123", "run_1")
    assert_equal "https://api.test/monitors/mon_123/runs/run_1", @requester.requests.last[:url].to_s
  end

  private

  def json_response(body)
    lambda do |_req|
      response = TestSupport::FakeResponse.new("200", {"content-type" => "application/json"})
      [200, response, [body.to_json].each]
    end
  end
end
