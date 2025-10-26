# Changelog

## [1.1.0] - Unreleased
- Add the `exa` CLI entrypoint (installed automatically with the gem) including multi-account credential management and JSON-friendly output helpers.
- Introduce a secure YAML config store (`~/.config/exa/config.yml`) and CLI commands for `accounts:list`, `accounts:add`, `accounts:use`, and `accounts:remove`.
- Implement the first API-facing CLI surface (`search:run`, `search:contents`) plus serialization helpers, client bootstrapping, and TDD coverage (Aruba + unit tests) as outlined in `docs/cli-plan.md`.

## [1.0.0] - 2025-10-26
- First stable release of the typed Exa API client.
- Covers search, research, websets, monitors, imports, events, and webhooks resources based on the OpenAPI spec.
- Adds Sorbet-backed request/response structs, schema-aware structured output helpers, retrying transport, and streaming utilities.
- Bundles developer ergonomics: connection pooling, pagination helpers, JSON/SSE streaming, and extensive README docs.

## [0.1.0] - 2025-10-25
- Initial gem scaffolding.
