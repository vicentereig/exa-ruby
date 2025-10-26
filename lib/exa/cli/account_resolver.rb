# frozen_string_literal: true

require_relative "config_store"

module Exa
  module CLI
    class AccountResolver
      DEFAULT_BASE_URL = "https://api.exa.ai"

      Result = Struct.new(:api_key, :base_url, :account, keyword_init: true)

      class MissingCredentialsError < StandardError; end
      class UnknownAccountError < StandardError; end

      def initialize(config_store:)
        @config_store = config_store
      end

      def resolve(options:, env: ENV)
        data = config_store.read
        account_name = options[:account] || env["EXA_ACCOUNT"] || data["default"]
        account_data = fetch_account(data, account_name) if account_name

        api_key = options[:api_key] ||
                  env["EXA_API_KEY"] ||
                  account_data&.dig("api_key")

        base_url = options[:base_url] ||
                   env["EXA_BASE_URL"] ||
                   account_data&.dig("base_url") ||
                   DEFAULT_BASE_URL

        unless api_key
          raise MissingCredentialsError,
                "Missing API key. Provide --api-key, set EXA_API_KEY, or add an account via `exa accounts:add`."
        end

        Result.new(api_key: api_key, base_url: base_url, account: account_name)
      end

      private

      attr_reader :config_store

      def fetch_account(data, name)
        account = data["accounts"][name]
        raise UnknownAccountError, "Account #{name.inspect} not found" unless account

        account
      end
    end
  end
end
