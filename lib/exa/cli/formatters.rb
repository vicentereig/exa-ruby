# frozen_string_literal: true

require "json"

module Exa
  module CLI
    module Formatters
      def self.for(name)
        case name&.to_s&.downcase
        when "json"
          JsonFormatter.new
        when "jsonl"
          JsonlFormatter.new
        when "markdown"
          MarkdownFormatter.new
        else
          TableFormatter.new
        end
      end

      class BaseFormatter
        def render(cli:, payload:, collection:)
          raise NotImplementedError
        end

        private

        def serialize(cli, object)
          cli.send(:serializable, object)
        end
      end

      class JsonFormatter < BaseFormatter
        def render(cli:, payload:, collection:)
          cli.say JSON.pretty_generate(serialize(cli, payload))
        end
      end

      class JsonlFormatter < BaseFormatter
        def render(cli:, payload:, collection:)
          items = collection && !collection.empty? ? collection : [payload]
          items.each do |item|
            cli.say JSON.generate(serialize(cli, item))
          end
        end
      end

      class MarkdownFormatter < BaseFormatter
        def render(cli:, payload:, collection:)
          if collection && !collection.empty?
            collection.each do |item|
              cli.say "- #{markdown_line(cli, item)}"
            end
          else
            cli.say "```json"
            cli.say JSON.pretty_generate(serialize(cli, payload))
            cli.say "```"
          end
        end

        private

        def markdown_line(cli, item)
          title = cli.send(:value_from, item, :title) || cli.send(:value_from, item, :name)
          url = cli.send(:value_from, item, :url)
          id = cli.send(:value_from, item, :id)
          primary = title || id || cli.send(:serializable, item)

          line = primary.is_a?(String) ? primary : primary.to_s
          line = "[#{line}](#{url})" if url
          line += " (#{id})" if id && (title || url)
          line
        end
      end

      class TableFormatter < BaseFormatter
        def render(cli:, payload:, collection:)
          if collection && !collection.empty?
            collection.each_with_index do |item, index|
              cli.say cli.send(:format_collection_entry, item, index)
            end
          elsif collection
            cli.say "No results."
          else
            cli.say cli.send(:format_single_entry, payload)
          end
        end
      end
    end
  end
end
