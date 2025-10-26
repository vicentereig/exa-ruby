# frozen_string_literal: true

require "test_helper"
require "json"
require "aruba/api"

class AccountsCommandsTest < Minitest::Test
  include Aruba::Api

  def setup
    super
    setup_aruba
    @project_root = File.expand_path("../..", __dir__)
    @bundle = File.expand_path("~/.rbenv/shims/bundle")
    @exe = File.join(@project_root, "exe/exa")
    @config_dir = File.join(expand_path("."), ".exa-cli")
    set_environment_variable("EXA_CONFIG_DIR", @config_dir)
    set_environment_variable("BUNDLE_GEMFILE", File.join(@project_root, "Gemfile"))
    set_environment_variable("PATH", "#{File.expand_path('~/.rbenv/shims')}:#{ENV.fetch('PATH', '')}")
  end

  def test_lists_empty_state
    run_cli("accounts:list")
    assert_includes last_command_started.stdout, "No accounts configured"
    assert_success(last_command_started)
  end

  def test_adds_account_and_sets_default
    run_cli("accounts:add prod --api-key exa_prod --base-url https://api.exa.ai")
    assert_success(last_command_started)
    run_cli("accounts:list --json")
    assert_success(last_command_started)
    data = JSON.parse(last_command_started.stdout)
    assert_equal "prod", data["default"]
    assert_equal "exa_prod", data["accounts"]["prod"]["api_key"]
  end

  def test_can_switch_default_account
    run_cli("accounts:add prod --api-key prod --base-url https://api.exa.ai")
    run_cli("accounts:add staging --api-key staging --base-url https://staging.exa.ai --no-default")
    run_cli("accounts:use staging")

    run_cli("accounts:list --json")
    data = JSON.parse(last_command_started.stdout)
    assert_equal "staging", data["default"]
  end

  def test_removing_default_account_clears_default
    run_cli("accounts:add prod --api-key prod --base-url https://api.exa.ai")
    run_cli("accounts:remove prod --yes")

    run_cli("accounts:list --json")
    data = JSON.parse(last_command_started.stdout)
    assert_nil data["default"]
    assert_empty data["accounts"]
  end

  private

  def run_cli(args)
    run_command("#{@bundle} exec #{@exe} #{args}")
    last_command_started.stop
  end

  def assert_success(command)
    assert_equal 0, command.exit_status, "expected success, got #{command.exit_status}. stderr:\n#{command.stderr}"
  end
end
