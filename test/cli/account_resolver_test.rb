# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "exa/cli/account_resolver"
require "exa/cli/config_store"

module Exa
  module CLI
    class AccountResolverTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir
        @config_path = File.join(@tmp_dir, "config.yml")
        @store = ConfigStore.new(path: @config_path)
        @resolver = AccountResolver.new(config_store: @store)
      end

      def teardown
        FileUtils.remove_entry(@tmp_dir)
      end

      def test_prefers_explicit_api_key_over_everything_else
        @store.upsert_account("prod", api_key: "stored", base_url: "https://api.exa.ai")
        options = { account: "prod", api_key: "override", base_url: "https://custom" }

        resolved = @resolver.resolve(options: options, env: {})

        assert_equal "override", resolved.api_key
        assert_equal "https://custom", resolved.base_url
        assert_equal "prod", resolved.account
      end

      def test_falls_back_to_env_when_api_key_missing
        env = { "EXA_API_KEY" => "from_env", "EXA_BASE_URL" => "https://env" }
        resolved = @resolver.resolve(options: {}, env: env)

        assert_equal "from_env", resolved.api_key
        assert_equal "https://env", resolved.base_url
        assert_nil resolved.account
      end

      def test_uses_named_account_from_store
        @store.upsert_account("prod", api_key: "stored", base_url: "https://api.exa.ai")
        resolved = @resolver.resolve(options: { account: "prod" }, env: {})

        assert_equal "stored", resolved.api_key
        assert_equal "https://api.exa.ai", resolved.base_url
        assert_equal "prod", resolved.account
      end

      def test_uses_default_account_when_no_overrides_present
        @store.upsert_account("prod", api_key: "stored", base_url: "https://api.exa.ai")
        @store.set_default("prod")

        resolved = @resolver.resolve(options: {}, env: {})

        assert_equal "stored", resolved.api_key
        assert_equal "prod", resolved.account
      end

      def test_raises_when_requested_account_missing
        error = assert_raises(AccountResolver::UnknownAccountError) do
          @resolver.resolve(options: { account: "nope" }, env: {})
        end

        assert_match(/nope/, error.message)
      end

      def test_raises_when_no_credentials_can_be_found
        error = assert_raises(AccountResolver::MissingCredentialsError) do
          @resolver.resolve(options: {}, env: {})
        end

        assert_match(/EXA_API_KEY/, error.message)
      end
    end
  end
end
