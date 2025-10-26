# Changelog

## [1.1.1] - 2025-10-26
- Add CLI output formatters: `--format jsonl` emits one JSON object per line, and `--format markdown` prints share-ready bullet lists/tables.
- Document copy-paste ready CLI and Ruby API examples in the README so users/LLMs can get started instantly.

## [1.1.0] - 2025-10-26
- Add the `exa` CLI entrypoint (installed automatically with the gem) including multi-account credential management and JSON-friendly output helpers.
- Introduce a secure YAML config store (`~/.config/exa/config.yml`) and CLI commands for `accounts:list`, `accounts:add`, `accounts:use`, and `accounts:remove`.
- Expand the CLI surface to cover search (run/contents/similar/answer), research (create/list/get/cancel), websets (core, items, enrichments, monitors), imports, events, and webhooks, with shared JSON payload helpers and basic streaming support (`search:answer --stream`, `research:get --stream`), all exercised via new unit + Aruba tests following `docs/cli-plan.md`.

## [1.0.0] - 2025-10-26
- First stable release of the typed Exa API client.
- Covers search, research, websets, monitors, imports, events, and webhooks resources based on the OpenAPI spec.
- Adds Sorbet-backed request/response structs, schema-aware structured output helpers, retrying transport, and streaming utilities.
- Bundles developer ergonomics: connection pooling, pagination helpers, JSON/SSE streaming, and extensive README docs.

## [0.1.0] - 2025-10-25
- Initial gem scaffolding.
