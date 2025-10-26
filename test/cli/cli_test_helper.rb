# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "exa/cli"

module CliTestHelper
  def setup_cli_config
    @tmp_dir = Dir.mktmpdir
    @config_path = File.join(@tmp_dir, "config.yml")
    store = Exa::CLI::ConfigStore.new(path: @config_path)
    store.upsert_account("prod", api_key: "test-key", base_url: "https://cli.test")
    store.set_default("prod")
  end

  def teardown_cli_config
    FileUtils.remove_entry(@tmp_dir) if defined?(@tmp_dir) && @tmp_dir && Dir.exist?(@tmp_dir)
  end

  def cli_config_path
    @config_path
  end
end
