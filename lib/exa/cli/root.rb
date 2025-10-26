# frozen_string_literal: true

require "thor"
require "json"
require "exa"
require_relative "config_store"
require_relative "account_resolver"

module Exa
  module CLI
    class Root < Thor
      def self.exit_on_failure?
        true
      end

      map "accounts:list" => :accounts_list
      map "accounts:add" => :accounts_add
      map "accounts:use" => :accounts_use
      map "accounts:remove" => :accounts_remove
      map "search:run" => :search_run
      map "search:contents" => :search_contents

      class_option :account, type: :string, desc: "Use a named account from your exa config"
      class_option :api_key, type: :string, desc: "Override the API key for this invocation"
      class_option :base_url, type: :string, desc: "Override the API base URL"
      class_option :config, type: :string, desc: "Path to the exa CLI config file"
      class_option :format, type: :string, default: "table", desc: "Output format: table, json, or raw"

      desc "version", "Print the CLI and gem version"
      def version
        say "exa-ai-ruby #{Exa::VERSION}"
      end

      desc "accounts:list", "List stored accounts"
      option :json, type: :boolean, default: false, desc: "Emit JSON instead of a table"
      def accounts_list
        data = config_store.read
        if options[:json]
          say JSON.pretty_generate(data)
          return
        end

        if data["accounts"].empty?
          say "No accounts configured. Add one with `exa accounts:add NAME --api-key ...`."
          return
        end

        data["accounts"].each do |name, account|
          marker = data["default"] == name ? "*" : " "
          say "#{marker} #{name.ljust(12)} #{account['base_url']}"
        end
      end

      desc "accounts:add NAME", "Add or update an account credential"
      option :api_key, type: :string, required: true, desc: "API key to store"
      option :base_url, type: :string, default: AccountResolver::DEFAULT_BASE_URL, desc: "API base URL"
      option :default, type: :boolean, default: true, desc: "Set as the default account"
      def accounts_add(name)
        config_store.upsert_account(
          name,
          api_key: options[:api_key],
          base_url: options[:base_url],
          make_default: options[:default]
        )
        config_store.set_default(name) if options[:default]
        say "Saved account '#{name}'."
      rescue ConfigStore::UnknownAccountError => e
        raise Thor::Error, e.message
      end

      desc "accounts:use NAME", "Set the default account"
      def accounts_use(name)
        config_store.set_default(name)
        say "Default account set to '#{name}'."
      rescue ConfigStore::UnknownAccountError => e
        raise Thor::Error, e.message
      end

      desc "accounts:remove NAME", "Delete a stored account"
      option :yes, type: :boolean, default: false, desc: "Confirm deletion without prompting"
      def accounts_remove(name)
        unless options[:yes]
          raise Thor::Error, "Pass --yes to confirm account deletion."
        end

        removed = config_store.remove_account(name)
        if removed
          say "Removed account '#{name}'."
        else
          raise Thor::Error, "Account '#{name}' not found."
        end
      end

      desc "search:run QUERY", "Run a search query against the Exa API"
      option :num_results, type: :numeric, desc: "Number of results to return"
      option :text, type: :boolean, default: false, desc: "Include page text in the response"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def search_run(query)
        payload = { query: query }
        payload[:num_results] = options[:num_results].to_i if options[:num_results]
        payload[:text] = true if options[:text]
        response = client.search.search(payload)
        render_response(response, json: options[:json])
      end

      desc "search:contents", "Fetch contents for specific URLs"
      option :urls, type: :string, desc: "Comma-separated list of URLs"
      option :file, type: :string, desc: "File containing URLs (one per line)"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def search_contents
        urls = []
        urls.concat(split_list(options[:urls])) if options[:urls]
        urls.concat(read_urls_from_file(options[:file])) if options[:file]
        urls.map!(&:strip)
        urls.reject!(&:empty?)
        urls.uniq!

        if urls.empty?
          raise Thor::Error, "Provide URLs via --urls or --file."
        end

        response = client.search.contents(urls: urls)
        render_response(response, json: options[:json])
      end

      no_commands do
        def config_store
          @config_store ||= Exa::CLI::ConfigStore.new(path: options[:config])
        end

        def account_resolver
          @account_resolver ||= Exa::CLI::AccountResolver.new(config_store: config_store)
        end

        def client
          @client ||= begin
            credentials = account_resolver.resolve(options: options, env: ENV)
            Exa::Client.new(api_key: credentials.api_key, base_url: credentials.base_url)
          end
        end

        def render_response(response, json:)
          if json
            payload = serializable(response)
            say JSON.pretty_generate(payload)
            return
          end

          results = if response.respond_to?(:results)
                      Array(response.results)
                    elsif response.is_a?(Hash) && response["results"]
                      Array(response["results"])
                    else
                      []
                    end

          if results.empty?
            say "No results."
            return
          end

          results.each_with_index do |result, index|
            title = value_from(result, :title) || "(untitled)"
            url = value_from(result, :url)
            say "#{index + 1}. #{title}#{url ? " (#{url})" : ""}"
          end
        end

        def split_list(value)
          value.split(",").map(&:strip)
        end

        def read_urls_from_file(path)
          return [] unless path

          File.read(File.expand_path(path)).lines
        rescue Errno::ENOENT
          raise Thor::Error, "File not found: #{path}"
        end

        def serializable(object)
          case object
          when nil, Numeric, String, TrueClass, FalseClass
            object
          when Array
            object.map { |item| serializable(item) }
          when Hash
            object.transform_values { |value| serializable(value) }
          else
            if object.respond_to?(:serialize)
              serializable(object.serialize)
            elsif object.respond_to?(:to_hash)
              serializable(object.to_hash)
            else
              object
            end
          end
        end

        def value_from(result, key)
          if result.respond_to?(key)
            result.public_send(key)
          elsif result.is_a?(Hash)
            result[key.to_s] || result[key]
          end
        end
      end
    end
  end
end
