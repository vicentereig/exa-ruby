# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "exa/cli/config_store"

module Exa
  module CLI
    class ConfigStoreTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir
        @path = File.join(@tmp_dir, "#{name}.yml")
        @store = ConfigStore.new(path: @path)
      end

      def teardown
        FileUtils.remove_entry(@tmp_dir)
      end

      def test_returns_default_structure_when_file_missing
        config = @store.read

        assert_equal 1, config["version"]
        assert_equal({}, config["accounts"])
        assert_nil config["default"]
      end

      def test_upserts_account_and_persists_to_disk
        @store.upsert_account("prod", api_key: "exa_prod", base_url: "https://api.exa.ai")
        data = @store.read

        assert_equal "exa_prod", data["accounts"]["prod"]["api_key"]
        assert_equal "https://api.exa.ai", data["accounts"]["prod"]["base_url"]
        assert_equal "prod", data["default"], "first account should become default"
        assert_equal 0o600, File.stat(@path).mode & 0o777
      end

      def test_can_update_existing_account_without_changing_default
        @store.upsert_account("prod", api_key: "old", base_url: "https://api.exa.ai")
        @store.set_default("prod")
        @store.upsert_account("prod", api_key: "new", base_url: "https://api.exa.ai")

        data = @store.read
        assert_equal "prod", data["default"]
        assert_equal "new", data["accounts"]["prod"]["api_key"]
      end

      def test_can_remove_account_and_clears_default_if_needed
        @store.upsert_account("prod", api_key: "key", base_url: "https://api.exa.ai")
        @store.upsert_account("staging", api_key: "key2", base_url: "https://staging")
        @store.set_default("prod")

        @store.remove_account("prod")
        data = @store.read

        refute_includes data["accounts"].keys, "prod"
        assert_nil data["default"], "default should reset when account deleted"
      end

      def test_set_default_raises_when_account_missing
        error = assert_raises(ConfigStore::UnknownAccountError) { @store.set_default("nope") }
        assert_match(/nope/, error.message)
      end
    end
  end
end
