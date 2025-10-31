# frozen_string_literal: true

require "test_helper"
require "json"
require "async"
require "async/http/client"
require "async/http/server"
require "async/http/endpoint"
require "webrick"
require "uri"

class AsyncRequesterTest < Minitest::Test
  def setup
    @server = nil
    @server_thread = nil
  end

  def teardown
    @server&.shutdown
    @server_thread&.join
  end

  def test_requires_async_scheduler
    requester = load_requester
    request = build_request("http://127.0.0.1:1/health")
    error = assert_raises(Exa::Errors::ConfigurationError) { requester.execute(request) }
    assert_match(/Async scheduler/, error.message)
  end

  def test_executes_request_and_streams_body
    port = start_webrick

    result = nil
    Async do
      requester = load_requester
      request = build_request("http://127.0.0.1:#{port}/echo", method: :post, body: {hello: "world"}.to_json, headers: {"content-type" => "application/json"})
      status, response, body_enum = requester.execute(request)
      headers = {}
      response.each_header { |key, value| headers[key.downcase] = value }
      result = {
        status: status,
        headers: headers,
        body: body_enum.to_a.join
      }
      requester.close
    end.wait

    assert_equal 200, result[:status]
    assert_equal "application/json", result[:headers]["content-type"]
    assert_equal({ok: true}.to_json, result[:body])
  end

  private

  def load_requester
    require "exa/internal/transport/async_requester"
    Exa::Internal::Transport::AsyncRequester.new
  end

  def build_request(url, method: :get, body: nil, headers: {})
    {
      method: method,
      url: URI(url),
      headers: headers,
      body: body,
      deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
    }
  end

  def start_webrick
    port = free_port
    @server = WEBrick::HTTPServer.new(
      Port: port,
      BindAddress: "127.0.0.1",
      Logger: WEBrick::Log.new(File::NULL),
      AccessLog: []
    )
    @server.mount_proc "/echo" do |_req, res|
      res.status = 200
      res["Content-Type"] = "application/json"
      res.body = {ok: true}.to_json
    end
    @server_thread = Thread.new { @server.start }
    port
  end

  def free_port
    server = TCPServer.new("127.0.0.1", 0)
    port = server.addr[1]
    server.close
    port
  end
end
