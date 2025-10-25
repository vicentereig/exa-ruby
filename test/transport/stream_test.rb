# frozen_string_literal: true

require "test_helper"

class StreamTest < Minitest::Test
  def test_each_event_json_decodes_payload_and_closes_stream
    closed = false
    enum = Exa::Internal::Util.fused_enum(
      [
        "id:1\n",
        "event:message\n",
        "data:{\"value\":42}\n\n"
      ].each
    ) { closed = true }

    stream = Exa::Internal::Transport::Stream.new(headers: {"content-type" => "text/event-stream"}, stream: enum)
    events = []
    stream.each_event_json { |event| events << event }

    assert closed
    assert_equal 1, events.length
    event = events.first
    assert_equal "message", event[:event]
    assert_equal({value: 42}, event[:data])
    assert_equal "1", event[:id]
  end

  def test_each_json_line_parses_lines
    closed = false
    chunks = ["{\"foo\":1}\n", "{\"bar\":2}\n"]
    enum = Exa::Internal::Util.fused_enum(chunks.each) { closed = true }
    stream = Exa::Internal::Transport::Stream.new(headers: {"content-type" => "application/x-ndjson"}, stream: enum)

    payloads = []
    stream.each_json_line { |obj| payloads << obj }

    assert closed
    assert_equal [{foo: 1}, {bar: 2}], payloads
  end
end
