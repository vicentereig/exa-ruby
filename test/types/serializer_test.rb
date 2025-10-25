# frozen_string_literal: true

require "test_helper"

class ExampleSummarySchema < T::Struct
  const :title, String
  const :url, String
  const :is_primary_source, T::Boolean
end

class SerializerTest < Minitest::Test

  def test_search_request_serializes_to_camel_case
    request = Exa::Types::SearchRequest.new(
      query: "latest ai",
      num_results: 5,
      livecrawl_timeout: 10,
      text: Exa::Types::TextContentsOptions.new(max_characters: 1000, include_html_tags: false)
    )

    payload = request.to_payload
    assert_equal "latest ai", payload["query"]
    assert_equal 5, payload["numResults"]
    assert_equal 10, payload["livecrawlTimeout"]
    assert_equal 1000, payload.dig("text", "maxCharacters")
  end

  def test_find_similar_serializes_flags
    request = Exa::Types::FindSimilarRequest.new(
      url: "https://example.com",
      flags: ["experimental"],
      exclude_source_domain: true
    )
    payload = request.to_payload
    assert_equal "https://example.com", payload["url"]
    assert_equal true, payload["excludeSourceDomain"]
    assert_equal ["experimental"], payload["flags"]
  end

  def test_research_request_serializes_model_enum
    request = Exa::Types::ResearchCreateRequest.new(
      instructions: "Map robotics labs",
      model: Exa::Types::ResearchModel::Fast
    )
    payload = request.to_payload
    assert_equal "exa-research-fast", payload["model"]
  end

  def test_schema_module_generates_json_schema
    assert_equal "ExampleSummarySchema", ExampleSummarySchema.name
    schema = Exa::Types::Schema.to_json_schema(ExampleSummarySchema)
    assert_equal "object", schema[:type]
    assert_includes schema[:required], "title"
    assert_equal "string", schema.dig(:properties, :title, :type)
  end

  def test_serializer_converts_struct_class_to_json_schema
    options = Exa::Types::SummaryContentsOptions.new(schema: ExampleSummarySchema)
    payload = options.to_payload
    schema = payload["schema"]
    assert_equal "object", schema[:type]
    assert_includes schema[:required], "url"
  end

  def test_schema_maybe_convert_for_struct_class
    schema = Exa::Types::Schema.maybe_convert(ExampleSummarySchema)
    refute_nil schema
    assert_equal "object", schema[:type]
  end

  def test_research_request_accepts_schema_class
    request = Exa::Types::ResearchCreateRequest.new(
      instructions: "Map robotics labs",
      output_schema: ExampleSummarySchema
    )
    payload = request.to_payload
    schema = payload["outputSchema"]
    assert_equal "object", schema[:type]
    assert_equal "boolean", schema.dig(:properties, :is_primary_source, :type)
  end
end
