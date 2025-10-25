# frozen_string_literal: true

require "test_helper"

class ImportsResourceTest < Minitest::Test
  def setup
    requester = TestSupport::FakeRequester.new([])
    @client = Exa::Client.new(api_key: "abc", requester: requester, base_url: "https://api.test")
    @resource = @client.imports
    @requester = requester
  end

  def test_crud_paths
    @requester.push_responder(json_response(import_create_payload))
    created = @resource.create(name: "Initial")
    assert_kind_of Exa::Responses::ImportCreationResponse, created
    assert_equal "https://api.test/v0/imports", @requester.requests.last[:url].to_s

    @requester.push_responder(json_response(import_list_payload))
    listing = @resource.list(limit: 5)
    assert_kind_of Exa::Responses::ImportListResponse, listing
    assert_equal "https://api.test/v0/imports?limit=5", @requester.requests.last[:url].to_s

    @requester.push_responder(json_response(import_payload))
    retrieved = @resource.retrieve("imp_123")
    assert_kind_of Exa::Responses::Import, retrieved
    assert_equal "https://api.test/v0/imports/imp_123", @requester.requests.last[:url].to_s

    @requester.push_responder(json_response(import_payload(title: "Updated")))
    updated = @resource.update("imp_123", name: "Updated")
    assert_kind_of Exa::Responses::Import, updated
    assert_equal :patch, @requester.requests.last[:method]

    @requester.push_responder(json_response(import_payload(status: "deleted")))
    deleted = @resource.delete("imp_123")
    assert_kind_of Exa::Responses::Import, deleted
    assert_equal :delete, @requester.requests.last[:method]
  end

  private

  def import_payload(overrides = {})
    {
      id: "imp_123",
      object: "import",
      status: "pending",
      format: "csv",
      entity: {type: "company", name: "Acme"},
      title: "Initial",
      count: 10,
      metadata: {"env" => "test"},
      failedReason: nil,
      failedAt: nil,
      failedMessage: nil,
      createdAt: "2024-01-01T00:00:00Z",
      updatedAt: "2024-01-01T00:00:00Z"
    }.merge(overrides)
  end

  def import_create_payload
    import_payload.merge(
      uploadUrl: "https://upload.example.com",
      uploadValidUntil: "2024-01-01T01:00:00Z"
    )
  end

  def import_list_payload
    {
      data: [import_payload],
      hasMore: false,
      nextCursor: nil
    }
  end

  def json_response(body)
    lambda do |_req|
      response = TestSupport::FakeResponse.new("200", {"content-type" => "application/json"})
      [200, response, [body.to_json].each]
    end
  end
end
