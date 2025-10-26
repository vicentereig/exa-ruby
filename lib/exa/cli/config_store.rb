# frozen_string_literal: true

require "yaml"
require "fileutils"

module Exa
  module CLI
    class ConfigStore
      DEFAULT_RELATIVE_PATH = File.join(".config", "exa", "config.yml")
      DEFAULT_DATA = {
        "version" => 1,
        "accounts" => {},
        "default" => nil
      }.freeze

      class UnknownAccountError < StandardError; end

      attr_reader :path

      def initialize(path: nil, env: ENV)
        @env = env
        @path = path || env["EXA_CONFIG_PATH"] || File.join(config_dir(env), "config.yml")
      end

      def read
        if File.exist?(path)
          data = safe_load(File.read(path))
          normalize_data(data)
        else
          default_data
        end
      end

      def upsert_account(name, api_key:, base_url:, make_default: true)
        data = read
        data["accounts"][name] = {
          "api_key" => api_key,
          "base_url" => base_url
        }.compact
        data["default"] ||= name if make_default
        write(data)
      end

      def remove_account(name)
        data = read
        removed = data["accounts"].delete(name)
        return false unless removed

        data["default"] = nil if data["default"] == name
        write(data)
        true
      end

      def set_default(name)
        data = read
        unless data["accounts"].key?(name)
          raise UnknownAccountError, "Account #{name.inspect} not found"
        end

        data["default"] = name
        write(data)
      end

      private

      def config_dir(env)
        env["EXA_CONFIG_DIR"] || File.join(Dir.home, ".config", "exa")
      end

      def write(data)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, YAML.dump(data))
        File.chmod(0o600, path)
      end

      def safe_load(content)
        YAML.safe_load(content, permitted_classes: [], permitted_symbols: [], aliases: false) || {}
      rescue Psych::SyntaxError
        default_data
      end

      def normalize_data(data)
        normalized = default_data.merge(data.compact)
        normalized["accounts"] ||= {}
        normalized
      end

      def default_data
        {
          "version" => DEFAULT_DATA["version"],
          "accounts" => {},
          "default" => nil
        }
      end
    end
  end
end
