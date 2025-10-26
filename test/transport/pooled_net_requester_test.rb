# frozen_string_literal: true

require "test_helper"
require "webrick"

class PooledNetRequesterTest < Minitest::Test
  def setup
    @server = nil
    @server_thread = nil
  end

  def teardown
    @server&.shutdown
    @server_thread&.join
  end

  def test_single_http_request_per_execute_call
    requests = Queue.new
    port = free_port
    @server = WEBrick::HTTPServer.new(
      Port: port,
      BindAddress: "127.0.0.1",
      Logger: WEBrick::Log.new(File::NULL),
      AccessLog: []
    )
    @server.mount_proc "/echo" do |req, res|
      requests << req.body
      res.status = 200
      res["Content-Type"] = "application/json"
      res.body = {ok: true}.to_json
    end
    @server_thread = Thread.new { @server.start }

    requester = Exa::Internal::Transport::PooledNetRequester.new(size: 1)
    client = Exa::Client.new(
      api_key: "test-key",
      base_url: "http://127.0.0.1:#{port}",
      requester: requester
    )

    response = client.request(method: :post, path: "echo", body: {hello: "world"})
    assert_equal({ok: true}, response)

    assert_equal 1, requests.length, "expected a single HTTP request but multiple were made"
  end

  private

  def free_port
    server = TCPServer.new("127.0.0.1", 0)
    port = server.addr[1]
    server.close
    port
  end
end
