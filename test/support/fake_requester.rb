# frozen_string_literal: true

module TestSupport
  FakeResponse = Struct.new(:code, :headers) do
    def each_header(&blk)
      return headers.each_pair unless blk
      headers.each_pair(&blk)
    end

    def [](key)
      headers[key] || headers[key.to_s] || headers[key.to_s.downcase]
    end

    def get_fields(key)
      value = self[key]
      value ? [value] : nil
    end
  end

  class FakeRequester
    attr_reader :requests

    def initialize(responders)
      @responders = responders
      @requests = []
    end

    def push_responder(responder)
      @responders << responder
    end

    def execute(request)
      @requests << request
      responder = @responders.shift
      raise "No response stub" if responder.nil?
      responder.call(request)
    end
  end
end
