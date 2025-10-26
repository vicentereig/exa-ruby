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

      COLON_COMMANDS = %w[
        accounts:list
        accounts:add
        accounts:use
        accounts:remove
        search:run
        search:contents
        search:similar
        search:answer
        research:create
        research:list
        research:get
        research:cancel
        websets:create
        websets:list
        websets:get
        websets:update
        websets:delete
        websets:cancel
        websets:preview
        websets:items:list
        websets:items:get
        websets:items:delete
        websets:enrichments:create
        websets:enrichments:get
        websets:enrichments:update
        websets:enrichments:delete
        websets:enrichments:cancel
        monitors:create
        monitors:list
        monitors:get
        monitors:update
        monitors:delete
        monitors:runs:list
        monitors:runs:get
        imports:create
        imports:list
        imports:get
        imports:update
        imports:delete
        events:list
        events:get
        webhooks:list
        webhooks:create
        webhooks:get
        webhooks:update
        webhooks:delete
        webhooks:attempts
      ].freeze

      COLON_COMMANDS.each { |label| map label => label.tr(":", "_").to_sym }

      class_option :account, type: :string, desc: "Use a named account from your exa config"
      class_option :api_key, type: :string, desc: "Override the API key for this invocation"
      class_option :base_url, type: :string, desc: "Override the API base URL"
      class_option :config, type: :string, desc: "Path to the exa CLI config file"
      class_option :format, type: :string, default: "table", desc: "Output format: table, json, or raw"

      # Version -----------------------------------------------------------------

      desc "version", "Print the CLI and gem version"
      def version
        say "exa-ai-ruby #{Exa::VERSION}"
      end

      # Account management ------------------------------------------------------

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

      # Search ------------------------------------------------------------------

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

      desc "search:similar", "Find similar documents by id or URL"
      option :id, type: :string, desc: "Existing search result id"
      option :url, type: :string, desc: "URL to match"
      option :num_results, type: :numeric, desc: "Number of results to return"
      option :text, type: :boolean, default: false, desc: "Include page text"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def search_similar
        params = {}
        params[:id] = options[:id] if options[:id]
        params[:url] = options[:url] if options[:url]
        params[:num_results] = options[:num_results].to_i if options[:num_results]
        params[:text] = true if options[:text]
        if params[:id].nil? && params[:url].nil?
          raise Thor::Error, "Provide --id or --url."
        end

        response = client.search.find_similar(params)
        render_response(response, json: options[:json])
      end

      desc "search:answer QUERY", "Call the /answer endpoint"
      option :search_options, type: :string, desc: "JSON blob or @file with search options"
      option :schema, type: :string, desc: "JSON schema (inline or @file) for structured summary"
      option :stream, type: :boolean, default: false, desc: "Stream results as server-sent events"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON/events"
      def search_answer(query)
        payload = { query: query }
        if (opts = parse_json_option(options[:search_options], flag: "--search-options"))
          payload[:search_options] = opts
        end
        if (schema = parse_json_option(options[:schema], flag: "--schema"))
          payload[:summary] = { schema: schema }
        end
        payload[:stream] = true if options[:stream]

        response = client.search.answer(payload)
        if options[:stream]
          render_stream(response, json: options[:json])
        else
          render_response(response, json: options[:json])
        end
      end

      # Research ----------------------------------------------------------------

      desc "research:create", "Create a research run"
      option :instructions, type: :string, required: true, desc: "Research instructions"
      option :model, type: :string, desc: "Model name"
      option :schema, type: :string, desc: "JSON schema for output"
      option :events, type: :boolean, default: false, desc: "Request event stream"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def research_create
        payload = {
          instructions: options[:instructions]
        }
        payload[:model] = options[:model] if options[:model]
        if (schema = parse_json_option(options[:schema], flag: "--schema"))
          payload[:output_schema] = schema
        end
        payload[:events] = true if options[:events]

        response = client.research.create(payload)
        render_response(response, json: options[:json])
      end

      desc "research:list", "List research runs"
      option :status, type: :string, desc: "Filter by status"
      option :cursor, type: :string, desc: "Pagination cursor"
      option :limit, type: :numeric, desc: "Max results to return"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def research_list
        params = compact_hash(
          status: options[:status],
          cursor: options[:cursor],
          limit: options[:limit]&.to_i
        )
        response = client.research.list(params.empty? ? nil : params)
        render_response(response, json: options[:json])
      end

      desc "research:get ID", "Fetch a research run"
      option :events, type: :boolean, default: false, desc: "Include events in the response"
      option :stream, type: :boolean, default: false, desc: "Stream updates"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def research_get(id)
        response = client.research.get(id, events: options[:events], stream: options[:stream])
        if options[:stream]
          render_stream(response, json: options[:json])
        else
          render_response(response, json: options[:json])
        end
      end

      desc "research:cancel ID [ID...]", "Cancel one or more research runs"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def research_cancel(*ids)
        if ids.empty?
          raise Thor::Error, "Provide at least one research id."
        end

        ids.each do |research_id|
          response = client.research.cancel(research_id)
          render_response(response, json: options[:json])
        end
      end

      # Websets -----------------------------------------------------------------

      desc "websets:create", "Create a webset"
      option :data, type: :string, required: true, desc: "JSON payload or @file containing create params"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def websets_create
        payload = parse_required_json_option!(options[:data], flag: "--data")
        response = client.websets.create(payload)
        render_response(response, json: options[:json])
      end

      desc "websets:list", "List websets"
      option :cursor, type: :string, desc: "Pagination cursor"
      option :limit, type: :numeric, desc: "Limit page size"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def websets_list
        params = compact_hash(
          cursor: options[:cursor],
          limit: options[:limit]&.to_i
        )
        response = client.websets.list(params.empty? ? nil : params)
        render_response(response, json: options[:json])
      end

      desc "websets:get ID", "Retrieve a single webset"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def websets_get(id)
        response = client.websets.retrieve(id)
        render_response(response, json: options[:json])
      end

      desc "websets:update ID", "Update a webset"
      option :data, type: :string, required: true, desc: "JSON payload or @file"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def websets_update(id)
        payload = parse_required_json_option!(options[:data], flag: "--data")
        response = client.websets.update(id, payload)
        render_response(response, json: options[:json])
      end

      desc "websets:delete ID", "Delete a webset"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def websets_delete(id)
        response = client.websets.delete(id)
        render_response(response, json: options[:json])
      end

      desc "websets:cancel ID", "Cancel all searches/enrichments for a webset"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def websets_cancel(id)
        response = client.websets.cancel(id)
        render_response(response, json: options[:json])
      end

      desc "websets:preview", "Preview changes to a webset definition"
      option :data, type: :string, required: true, desc: "JSON payload or @file"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def websets_preview
        payload = parse_required_json_option!(options[:data], flag: "--data")
        response = client.websets.preview(payload)
        render_response(response, json: options[:json])
      end

      # Webset items ------------------------------------------------------------

      desc "websets:items:list WEBSET_ID", "List items belonging to a webset"
      option :cursor, type: :string, desc: "Pagination cursor"
      option :limit, type: :numeric, desc: "Limit"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def websets_items_list(webset_id)
        params = compact_hash(
          cursor: options[:cursor],
          limit: options[:limit]&.to_i
        )
        response = client.websets.items.list(webset_id, params.empty? ? nil : params)
        render_response(response, json: options[:json])
      end

      desc "websets:items:get WEBSET_ID ITEM_ID", "Retrieve a webset item"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def websets_items_get(webset_id, item_id)
        response = client.websets.items.retrieve(webset_id, item_id)
        render_response(response, json: options[:json])
      end

      desc "websets:items:delete WEBSET_ID ITEM_ID", "Delete an item"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def websets_items_delete(webset_id, item_id)
        response = client.websets.items.delete(webset_id, item_id)
        render_response(response, json: options[:json])
      end

      # Webset enrichments ------------------------------------------------------

      desc "websets:enrichments:create WEBSET_ID", "Create an enrichment"
      option :data, type: :string, required: true, desc: "JSON payload or @file"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def websets_enrichments_create(webset_id)
        payload = parse_required_json_option!(options[:data], flag: "--data")
        response = client.websets.enrichments.create(webset_id, payload)
        render_response(response, json: options[:json])
      end

      desc "websets:enrichments:get WEBSET_ID ENRICHMENT_ID", "Retrieve enrichment details"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def websets_enrichments_get(webset_id, enrichment_id)
        response = client.websets.enrichments.retrieve(webset_id, enrichment_id)
        render_response(response, json: options[:json])
      end

      desc "websets:enrichments:update WEBSET_ID ENRICHMENT_ID", "Update an enrichment"
      option :data, type: :string, required: true, desc: "JSON payload or @file"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def websets_enrichments_update(webset_id, enrichment_id)
        payload = parse_required_json_option!(options[:data], flag: "--data")
        response = client.websets.enrichments.update(webset_id, enrichment_id, payload)
        render_response(response, json: options[:json])
      end

      desc "websets:enrichments:delete WEBSET_ID ENRICHMENT_ID", "Delete an enrichment"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def websets_enrichments_delete(webset_id, enrichment_id)
        response = client.websets.enrichments.delete(webset_id, enrichment_id)
        render_response(response, json: options[:json])
      end

      desc "websets:enrichments:cancel WEBSET_ID ENRICHMENT_ID", "Cancel an enrichment"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def websets_enrichments_cancel(webset_id, enrichment_id)
        response = client.websets.enrichments.cancel(webset_id, enrichment_id)
        render_response(response, json: options[:json])
      end

      # Monitors ----------------------------------------------------------------

      desc "monitors:create", "Create a monitor"
      option :data, type: :string, required: true, desc: "JSON payload or @file"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def monitors_create
        payload = parse_required_json_option!(options[:data], flag: "--data")
        response = client.websets.monitors.create(payload)
        render_response(response, json: options[:json])
      end

      desc "monitors:list", "List monitors"
      option :cursor, type: :string, desc: "Pagination cursor"
      option :limit, type: :numeric, desc: "Limit page size"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def monitors_list
        params = compact_hash(
          cursor: options[:cursor],
          limit: options[:limit]&.to_i
        )
        response = client.websets.monitors.list(params.empty? ? nil : params)
        render_response(response, json: options[:json])
      end

      desc "monitors:get ID", "Retrieve a monitor"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def monitors_get(id)
        response = client.websets.monitors.retrieve(id)
        render_response(response, json: options[:json])
      end

      desc "monitors:update ID", "Update a monitor"
      option :data, type: :string, required: true, desc: "JSON payload or @file"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def monitors_update(id)
        payload = parse_required_json_option!(options[:data], flag: "--data")
        response = client.websets.monitors.update(id, payload)
        render_response(response, json: options[:json])
      end

      desc "monitors:delete ID", "Delete a monitor"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def monitors_delete(id)
        response = client.websets.monitors.delete(id)
        render_response(response, json: options[:json])
      end

      desc "monitors:runs:list ID", "List monitor runs"
      option :cursor, type: :string, desc: "Pagination cursor"
      option :limit, type: :numeric, desc: "Limit page size"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def monitors_runs_list(monitor_id)
        params = compact_hash(
          cursor: options[:cursor],
          limit: options[:limit]&.to_i
        )
        response = client.websets.monitors.runs_list(monitor_id, params.empty? ? nil : params)
        render_response(response, json: options[:json])
      end

      desc "monitors:runs:get MONITOR_ID RUN_ID", "Get a specific monitor run"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def monitors_runs_get(monitor_id, run_id)
        response = client.websets.monitors.runs_get(monitor_id, run_id)
        render_response(response, json: options[:json])
      end

      # Imports -----------------------------------------------------------------

      desc "imports:create", "Create an import"
      option :data, type: :string, required: true, desc: "JSON payload or @file"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def imports_create
        payload = parse_required_json_option!(options[:data], flag: "--data")
        response = client.imports.create(payload)
        render_response(response, json: options[:json])
      end

      desc "imports:list", "List imports"
      option :cursor, type: :string, desc: "Pagination cursor"
      option :limit, type: :numeric, desc: "Limit page size"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def imports_list
        params = compact_hash(
          cursor: options[:cursor],
          limit: options[:limit]&.to_i
        )
        response = client.imports.list(params.empty? ? nil : params)
        render_response(response, json: options[:json])
      end

      desc "imports:get ID", "Retrieve an import"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def imports_get(id)
        response = client.imports.retrieve(id)
        render_response(response, json: options[:json])
      end

      desc "imports:update ID", "Update an import"
      option :data, type: :string, required: true, desc: "JSON payload or @file"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def imports_update(id)
        payload = parse_required_json_option!(options[:data], flag: "--data")
        response = client.imports.update(id, payload)
        render_response(response, json: options[:json])
      end

      desc "imports:delete ID", "Delete an import"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def imports_delete(id)
        response = client.imports.delete(id)
        render_response(response, json: options[:json])
      end

      # Events ------------------------------------------------------------------

      desc "events:list", "List events"
      option :cursor, type: :string, desc: "Pagination cursor"
      option :limit, type: :numeric, desc: "Limit"
      option :types, type: :string, desc: "Comma separated event types"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def events_list
        params = compact_hash(
          cursor: options[:cursor],
          limit: options[:limit]&.to_i,
          types: options[:types] ? split_list(options[:types]) : nil
        )
        response = client.events.list(params.empty? ? nil : params)
        render_response(response, json: options[:json])
      end

      desc "events:get ID", "Retrieve an event"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def events_get(id)
        response = client.events.retrieve(id)
        render_response(response, json: options[:json])
      end

      # Webhooks ----------------------------------------------------------------

      desc "webhooks:list", "List webhooks"
      option :cursor, type: :string, desc: "Pagination cursor"
      option :limit, type: :numeric, desc: "Limit"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def webhooks_list
        params = compact_hash(
          cursor: options[:cursor],
          limit: options[:limit]&.to_i
        )
        response = client.webhooks.list(params.empty? ? nil : params)
        render_response(response, json: options[:json])
      end

      desc "webhooks:create", "Create a webhook"
      option :data, type: :string, required: true, desc: "JSON payload or @file"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def webhooks_create
        payload = parse_required_json_option!(options[:data], flag: "--data")
        response = client.webhooks.create(payload)
        render_response(response, json: options[:json])
      end

      desc "webhooks:get ID", "Retrieve a webhook"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def webhooks_get(id)
        response = client.webhooks.retrieve(id)
        render_response(response, json: options[:json])
      end

      desc "webhooks:update ID", "Update a webhook"
      option :data, type: :string, required: true, desc: "JSON payload or @file"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def webhooks_update(id)
        payload = parse_required_json_option!(options[:data], flag: "--data")
        response = client.webhooks.update(id, payload)
        render_response(response, json: options[:json])
      end

      desc "webhooks:delete ID", "Delete a webhook"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def webhooks_delete(id)
        response = client.webhooks.delete(id)
        render_response(response, json: options[:json])
      end

      desc "webhooks:attempts ID", "List webhook delivery attempts"
      option :cursor, type: :string, desc: "Pagination cursor"
      option :limit, type: :numeric, desc: "Limit"
      option :json, type: :boolean, default: false, desc: "Emit raw JSON"
      def webhooks_attempts(id)
        params = compact_hash(
          cursor: options[:cursor],
          limit: options[:limit]&.to_i
        )
        response = client.webhooks.attempts(id, params.empty? ? nil : params)
        render_response(response, json: options[:json])
      end

      # Helpers -----------------------------------------------------------------

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

        def render_response(response, json:, collection_accessor: nil)
          payload = serializable(response)
          if json
            say JSON.pretty_generate(payload)
            return
          end

          collection = extract_collection(response, payload, collection_accessor)
          if collection
            if collection.empty?
              say "No results."
            else
              collection.each_with_index do |item, index|
                say format_collection_entry(item, index)
              end
            end
            return
          end

          say format_single_entry(payload)
        end

        def render_stream(stream, json:)
          if json
            stream.each do |chunk|
              say chunk.to_s
            end
            return
          end

          if stream.respond_to?(:each_event)
            stream.each_event do |event|
              say format_stream_event(event)
            end
          else
            stream.each { |chunk| say chunk.to_s }
          end
        ensure
          stream.close if stream.respond_to?(:close)
        end

        def format_stream_event(event)
          label = event[:event] || "event"
          data = event[:data]
          if data.nil? || data.empty?
            "[#{label}]"
          else
            "[#{label}] #{data}"
          end
        end

        def format_collection_entry(item, index)
          id = value_from(item, :id)
          primary = value_from(item, :title) ||
                    value_from(item, :name) ||
                    value_from(item, :url) ||
                    value_from(item, :status) ||
                    id ||
                    item.to_s
          suffix = id && primary != id ? " (#{id})" : ""
          "#{index + 1}. #{primary}#{suffix}"
        end

        def format_single_entry(payload)
          id = value_from(payload, :id)
          title = value_from(payload, :title) ||
                  value_from(payload, :name) ||
                  value_from(payload, :url) ||
                  value_from(payload, :status)
          return "#{id} - #{title}" if id && title
          return id.to_s if id
          return title.to_s if title

          payload.inspect
        end

        def extract_collection(response, payload, accessor)
          accessor ||= if response.respond_to?(:results)
                         :results
                       elsif response.respond_to?(:data)
                         :data
                       elsif payload.is_a?(Hash) && payload["results"]
                         "results"
                       elsif payload.is_a?(Hash) && payload["data"]
                         "data"
                       end
          return nil unless accessor

          if response.respond_to?(accessor)
            Array(response.public_send(accessor))
          elsif payload.is_a?(Hash)
            Array(payload[accessor.to_s] || payload[accessor.to_sym])
          end
        end

        def split_list(value)
          return [] if value.nil? || value.empty?
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

        def parse_required_json_option!(value, flag:)
          parsed = parse_json_option(value, flag: flag)
          return parsed unless parsed.nil?

          raise Thor::Error, "Provide #{flag} with a JSON payload or @file."
        end

        def parse_json_option(value, flag:)
          return nil if value.nil?

          content = if value.start_with?("@")
                      path = File.expand_path(value.delete_prefix("@"))
                      File.read(path)
                    else
                      value
                    end
          JSON.parse(content)
        rescue Errno::ENOENT
          raise Thor::Error, "File not found for #{flag}: #{value}"
        rescue JSON::ParserError => e
          raise Thor::Error, "Invalid JSON for #{flag}: #{e.message}"
        end

        def compact_hash(hash)
          hash.each_with_object({}) do |(key, val), acc|
            next if val.nil?
            if val.respond_to?(:empty?) && val.empty?
              next
            end
            acc[key] = val
          end
        end
      end
    end
  end
end
