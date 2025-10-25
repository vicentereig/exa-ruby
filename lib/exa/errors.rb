# frozen_string_literal: true

module Exa
  module Errors
    class Error < StandardError
      attr_reader :url, :status, :headers, :body

      def initialize(message = nil, url: nil, status: nil, headers: nil, body: nil)
        super(message)
        @url = url
        @status = status
        @headers = headers
        @body = body
      end
    end

    class ConfigurationError < Error; end
    class APIError < Error; end

    class APIStatusError < APIError
      def self.raise!(url:, status:, headers:, body:)
        message = "Exa API responded with status #{status}"
        raise new(message, url: url, status: status, headers: headers, body: body)
      end
    end

    class APIConnectionError < APIError; end
    class APITimeoutError < APIError; end
  end
end

module Exa
  Error = Exa::Errors::Error
end
