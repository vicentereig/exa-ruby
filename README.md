# Exa Ruby Client

[![Gem Version](https://img.shields.io/gem/v/exa-ai-ruby)](https://rubygems.org/gems/exa-ai-ruby)
[![Total Downloads](https://img.shields.io/gem/dt/exa-ai-ruby)](https://rubygems.org/gems/exa-ai-ruby)
[![Build Status](https://img.shields.io/github/actions/workflow/status/vicentereig/exa-ruby/ruby.yml?branch=main&label=tests)](https://github.com/vicentereig/exa-ruby/actions/workflows/ruby.yml)

> Typed, Sorbet-friendly Ruby bindings for the Exa API, inspired by `openai-ruby` and aligned with Exa’s OpenAPI specs.

This README is intentionally exhaustive—LLM agents and humans alike should be able to read it and learn how to use or extend the client without digging elsewhere.

---

## Table of Contents

1. [Project Goals](#project-goals)
2. [Environment & Installation](#environment--installation)
3. [Client Architecture Overview](#client-architecture-overview)
4. [CLI Quickstart](#cli-quickstart)
5. [Typed Resources & Usage Examples](#typed-resources--usage-examples)
   - [Search stack](#search-stack)
   - [Research](#research)
   - [Websets (core + items + enrichments + monitors)](#websets-core--items--enrichments--monitors)
   - [Events, Imports, Webhooks](#events-imports-webhooks)
6. [Structured Output via Sorbet + dspy-schema](#structured-output-via-sorbet--dspy-schema)
7. [Streaming & Transport Helpers](#streaming--transport-helpers)
8. [Testing & TDD Plan](#testing--tdd-plan)

---

## Project Goals

- Mirror `openai-ruby` ergonomics so Sorbet-aware developers get typed resources, model structs, and helpers out of the box.
- Port over OpenAI’s functional patterns: request structs, transport abstraction, streaming/pagination utilities, structured-output DSL.
- Understand the entire Exa API surface (search, contents, answers, research, websets, monitors, imports, events, webhooks, etc.) and encode it via Sorbet types generated from `openapi-spec/`.
- Bake Sorbet-generated JSON Schemas directly into v1 using the published `dspy-schema` gem—structured outputs should accept Sorbet types, not free-form hashes.

See `docs/architecture.md` for deep-dive notes, mermaid diagrams, and highlights from `openai-ruby`, `exa-py`, and `exa-js`.

---

## Environment & Installation

```
$ git clone https://github.com/vicentereig/exa-ruby
$ cd exa-ruby
$ rbenv install 3.4.5   # .ruby-version already pins this
$ bundle install
```

### Install via RubyGems

```
$ gem install exa-ai-ruby
```

### Install via Bundler

```ruby
# Gemfile
gem "exa-ai-ruby", "~> 1.0"
```

```
$ bundle install
```

Runtime dependencies:
- `sorbet-runtime` – typed structs/enums and runtime assertions.
- `connection_pool` – `Net::HTTP` pooling in `PooledNetRequester`.
- `dspy-schema` – converts Sorbet types to JSON Schema (structured output support).

Set the API key via `EXA_API_KEY` or pass `api_key:` when instantiating `Exa::Client`.

If you are building automation that calls this README (e.g., using `curl`/`wget` or a retrieval plug‑in), fetch the raw file from GitHub: `https://raw.githubusercontent.com/vicentereig/exa-ruby/main/README.md`.

---

## Client Architecture Overview

```ruby
require "exa"

client = Exa::Client.new(
  api_key: ENV.fetch("EXA_API_KEY"),
  base_url: ENV["EXA_BASE_URL"] || "https://api.exa.ai",
  timeout: 120,
  max_retries: 2
)
```

- `Exa::Client` inherits from `Exa::Internal::Transport::BaseClient`, giving us:
  - Header normalization + auth injection (`x-api-key`).
  - Retry/backoff logic with HTTP status checks.
  - Streaming support that returns `Exa::Internal::Transport::Stream`.
- Request payloads are Sorbet structs under `Exa::Types::*`, serialized via `Exa::Types::Serializer`, which camelizes keys and auto-converts Sorbet schemas (see [Structured Output](#structured-output-via-sorbet--dspy-schema)).
- Response models live in `lib/exa/responses/*`. Whenever an endpoint returns typed data the resource sets `response_model:` so the client converts the JSON hash into Sorbet structs (e.g., `Exa::Responses::SearchResponse`, `Webset`, `Research`, etc.).
- Transport stack:
  - `PooledNetRequester` manages per-origin `Net::HTTP` pools via `connection_pool`.
- Responses stream through fused enumerators so we can decode JSON/JSONL/SSE lazily and ensure sockets are closed once consumers finish iterating.

---

## CLI Quickstart

Starting with v1.1.0 the gem ships an `exa` executable that mirrors the API surface defined here. The CLI bootstraps the same typed client, so you get retries, streaming, and Sorbet-backed responses without writing Ruby.

1. **Install / update the gem and confirm the binary**

   ```
   $ gem install exa-ai-ruby
   $ exa version
   exa-ai-ruby 1.1.0
   ```

2. **Store credentials once** (per account) and let the CLI manage `~/.config/exa/config.yml` (override via `EXA_CONFIG_DIR` or `--config`). Files are chmod’d `0600`.

   ```
   $ exa accounts:add prod --api-key exa_prod_xxx --base-url https://api.exa.ai
   $ exa accounts:add staging --api-key exa_stage_xxx --base-url https://staging.exa.ai --no-default
   $ exa accounts:list
   * prod        https://api.exa.ai
     staging     https://staging.exa.ai
   $ exa accounts:use staging
   ```

   Every command accepts `--account`, `--api-key`, `--base-url`, `--config`, and `--format`. If omitted they fall back to the config file, environment variables (`EXA_ACCOUNT`, `EXA_API_KEY`, `EXA_BASE_URL`), or defaults.

3. **Call the API from any shell**

   ```
   # Run a typed search (pipe `--json` to jq or capture raw data)
   $ exa search:run "latest reasoning LLM papers" --num-results 3 --json

   # Fetch contents for explicit URLs
   $ exa search:contents --urls https://exa.ai,https://exa.com --json
   ```

   Omit `--json` for friendly summaries; include it when scripting so you get the Sorbet structs serialized as plain JSON.

Command families currently available:

- `exa search:*` – run searches, fetch contents, find similar results, or call `/answer` (with optional streaming).
- `exa research:*` – create/list/get/cancel research runs.
- `exa websets:*` – manage websets plus nested items, enrichments, and monitors (including monitor runs).
- `exa imports:*`, `exa events:*`, and `exa webhooks:*` – work with imports, audit events, and webhook endpoints/attempts.

The detailed roadmap, command matrix, and TDD expectations for future CLI work live in [`docs/cli-plan.md`](docs/cli-plan.md). See `test/cli/accounts_commands_test.rb` and `test/cli/search_commands_test.rb` for examples of the required coverage when you add new commands.

---

## Typed Resources & Usage Examples

### Search stack

```ruby
resp = client.search.search(
  query: "latest reasoning LLM papers",
  num_results: 5,
  text: {max_characters: 1_000}
)
resp.results.each { puts "#{_1.title} – #{_1.url}" }

contents = client.search.contents(urls: ["https://exa.ai"], text: true)

# Structured answer with typed search options + Sorbet schema
class AnswerShape < T::Struct
  const :headline, String
  const :key_points, T::Array[String]
end

answer = client.search.answer(
  query: "Summarize robotics grant funding",
  search_options: {num_results: 3, type: Exa::Types::SearchType::Deep},
  summary: {schema: AnswerShape}
)
puts answer.raw # Hash with schema-validated payload
```

Covers `/search`, `/contents`, `/findSimilar`, and `/answer` with typed request structs (`Exa::Types::SearchRequest`, etc.) and typed responses (`Exa::Responses::SearchResponse`, `FindSimilarResponse`, `ContentsResponse`).

### Research

```ruby
class ResearchShape < T::Struct
  const :organization, String
  const :funding_rounds, T::Array[String]
end

research = client.research.create(
  instructions: "Map frontier labs & their funders",
  output_schema: ResearchShape
)

# Polling
details = client.research.get(research.id)
puts details.status # pending/running/completed

# Streaming (Server-Sent Events)
client.research.get(research.id, stream: true).each_event_json do |event|
  puts "[#{event[:event]}] #{event[:data]}"
end

# Cancel
client.research.cancel(research.id)
```

Responses use `Exa::Responses::Research` and `ResearchListResponse`, which preserve raw payloads plus typed attributes (status, operations, events, output hashes, etc.). Streaming helpers (`each_event`, `each_event_json`) live on `Exa::Internal::Transport::Stream`.

### Websets (core + items + enrichments + monitors)

```ruby
webset = client.websets.create(name: "Competitive Intelligence")
webset = client.websets.update(webset.id, title: "Updated title")
list_resp = client.websets.list(limit: 10)

# Items
items = client.websets.items.list(webset.id, limit: 5)
item = client.websets.items.retrieve(webset.id, items.data.first.id)
client.websets.items.delete(webset.id, item.id)

# Enrichments
enrichment = client.websets.enrichments.create(
  webset.id,
  description: "Company revenue information",
  format: "text"
)
client.websets.enrichments.update(webset.id, enrichment.id, description: "Updated task")
client.websets.enrichments.cancel(webset.id, enrichment.id)

# Monitors
monitor = client.websets.monitors.create(name: "Daily digest")
runs = client.websets.monitors.runs_list(monitor.id)
```

Typed responses:
- `Exa::Responses::Webset`, `WebsetListResponse`
- `WebsetItem`, `WebsetItemListResponse`
- `WebsetEnrichment`
- `Monitor`, `MonitorRun`, etc.

### Events, Imports, Webhooks

```ruby
events = client.events.list(types: ["webset.created"])
event = client.events.retrieve(events.data.first.id)

import = client.imports.create(source: {...})
imports = client.imports.list(limit: 10)

webhook = client.webhooks.create(
  url: "https://example.com/hooks",
  events: ["webset.completed"]
)
attempts = client.webhooks.attempts(webhook.id, limit: 5)
```

Every call returns typed structs (`Exa::Responses::Event`, `Import`, `Webhook`, etc.) so consumers get predictable Sorbet shapes.

---

## Structured Output via Sorbet + dspy-schema

`dspy-schema`’s Sorbet converter is bundled so any Sorbet `T::Struct`, `T::Enum`, or `T.type_alias` can be dropped into a request payload and automatically serialized to JSON Schema. This powers `summary: {schema: ...}` and `research.output_schema`, letting the API validate outputs against your Sorbet model.

Key points:
- `Exa::Types::Schema.to_json_schema(SomeStruct)` calls `DSPy::TypeSystem::SorbetJsonSchema`.
- `Exa::Types::Serializer` detects Sorbet classes/aliases before serializing request payloads.
- Tests in `test/types/serializer_test.rb` ensure schema conversion works end-to-end.

---

## Streaming & Transport Helpers

- `Exa::Internal::Transport::Stream` (returned when `stream: true`) exposes:
  - `each` – raw chunk iteration.
  - `each_line` – line-by-line iteration with automatic closing.
  - `each_json_line(symbolize: true)` – NDJSON helper.
  - `each_event` / `each_event_json` – SSE decoding with automatic JSON parsing.
- `Exa::Internal::Util` utilities:
  - `decode_content` auto-detects JSON/JSONL/SSE vs binary bodies.
  - `decode_lines` + `decode_sse` implement fused enumerators so sockets close exactly once.
- `PooledNetRequester` calibrates socket timeouts per request deadline and reuses connections via `connection_pool`.
- Per-request overrides: pass `request_options: {timeout: 30, max_retries: 0, idempotency_key: SecureRandom.uuid}` to `Exa::Client#request` (exposed when constructing custom helpers) for fine-grained control.

See `test/transport/stream_test.rb` for examples.

---

## Testing & TDD Plan

Run the suite:

```
RBENV_VERSION=3.4.5 ~/.rbenv/shims/bundle exec rake test
```

Current coverage includes:
- Resource tests for search, research, websets (core/items/enrichments/monitors), imports, events, webhooks, etc., using `TestSupport::FakeRequester`.
- Type serialization tests ensuring camelCase conversion + schema inference.
- Streaming helper tests verifying SSE/JSONL decoding.

Future tests:
- End-to-end HTTP tests once a real transport target is wired (probably using recorded fixtures but not VCR).
- Schema-specific validations once JSON Schema generation is extended to all endpoints.

---

---

Have ideas or find gaps? Open an issue or PR in `vicentereig/exa-ruby`—contributions welcome!***
