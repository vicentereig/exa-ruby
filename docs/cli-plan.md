# exa CLI Plan (v1.1.0 target)

This document translates the existing Exa API surface (`lib/exa/resources/**/*` + `../openapi-spec/*`) into a Thor-based CLI that ships alongside the `exa-ai-ruby` gem. The CLI must:

- Share the same API client/runtime as the Ruby library.
- Bundle an `exa` executable (`exe/exa`) that works on macOS/Linux/Windows.
- Support multiple accounts/API keys with discoverable commands for managing them.
- Offer parity with the REST surface described in `exa-openapi-spec.yaml` and `exa-websets-spec.yaml`.
- Be developed test-first (Minitest + Aruba), exercising both happy paths and validation errors.

---

## Architecture & Config

- **Entry point**: `exe/exa` boots `Exa::CLI::Root` (Thor). Commands live under `lib/exa/cli/**/*`.
- **Global options** (Thor `class_option`s):
  - `--account NAME` (`EXA_ACCOUNT`) – pick named account from config.
  - `--api-key KEY` – override stored credential for one-off calls.
  - `--base-url URL` (`EXA_BASE_URL`, default `https://api.exa.ai`).
  - `--format FORMAT` (`json`, `table`, `compact`, `raw`).
  - `--output PATH` – write response to file.
  - `--timeout SEC`, `--max-retries N`, `--profile` (log timing + request id).
  - `--config FILE` (`EXA_CONFIG_PATH`) – override config location.
- **Config store**: YAML at `~/.config/exa/config.yml` (override via `EXA_CONFIG_DIR`). Shape:

  ```yaml
  version: 1
  default: prod
  accounts:
    prod:
      api_key: exa_prod_xxx
      base_url: https://api.exa.ai
    staging:
      api_key: exa_staging_xxx
      base_url: https://staging.exa.ai
  ```

- **Secret persistence**: file mode `0o600`. CLI warns if permissions broader.
- **Dependency additions**: `thor` for CLI, `tty-table` for tabular output, `aruba` (test), `webmock` (test), `pastel` (colors, optional), `fileutils`.

---

## Command Surface & Parameters

Each command mirrors a client resource; streamed endpoints default to SSE piping unless `--json` requested. Required parameters are positional; optional ones are flags. `@` prefix on flag value loads JSON/YAML from file (e.g., `--body @payload.json`).

### 1. Accounts & Auth Helpers

| Command | Description | Key flags |
| --- | --- | --- |
| `exa accounts:list` | Show stored accounts and defaults. | `--json`, `--show-keys` (explicit opt-in to reveal). |
| `exa accounts:add NAME --api-key KEY` | Add/update an account. | `--base-url URL`, `--default`, `--from-env VAR`, `--no-verify`. |
| `exa accounts:use NAME` | Set default account. | None. |
| `exa accounts:remove NAME` | Delete account. | `--force`. |
| `exa accounts:import FILE` | Merge YAML credentials. | `--set-default NAME`. |
| `exa whoami` | Hit `/events` or `/search` with `limit=0` to validate credentials, show default account + token scope. | `--account`, `--api-key`. |

### 2. Search Stack (`exa-openapi-spec.yaml`)

| Command | REST mapping | Required args | Important flags / params |
| --- | --- | --- | --- |
| `exa search run QUERY` | `POST /search` (`Exa::Resources::Search#search`) | `QUERY` | `--num-results`, `--include-domains`, `--exclude-domains`, `--start-crawl`, `--end-crawl`, `--type {auto,deep,live}`, `--category`, `--flags`, `--moderation`, `--livecrawl {auto,always,never}`, `--subpages`, `--text [on|off|max-chars=N|include-html]`, `--highlights [query=..|sentences=N]`, `--summary [schema=@schema.rb|query=..]`, `--context max-chars`, `--extras links=N,image-links=N`, `--raw` (emit API response). |
| `exa search contents --urls URL[,URL...]` | `POST /contents` | `--urls` or `--file list.txt` | `--text`, `--highlights`, `--summary`, `--timeout`, `--concurrency`. |
| `exa search similar ID|URL` | `POST /findSimilar` | ID or URL positional | `--num-results`, `--text`, `--highlights`, `--include-domains`, etc. |
| `exa search answer QUERY` | `POST /answer` | `QUERY` | `--search-options JSON`, `--stream`, `--schema @schema.rb`, `--temperature`, `--json`, `--explain`. Streaming prints SSE events; non-stream uses typed response. |

### 3. Research (`/research/v1`)

| Command | REST mapping | Notes |
| --- | --- | --- |
| `exa research create --instructions TEXT` | `POST /research/v1` | Flags: `--model`, `--schema @schema.rb`, `--stream`, `--events` (subscribe). Prints research id; `--watch` tails status. |
| `exa research list` | `GET /research/v1` | Filters: `--status`, `--limit`, `--cursor`. |
| `exa research get ID` | `GET /research/v1/{id}` | `--events` to include event payloads; `--stream` returns SSE. |
| `exa research cancel ID` | `POST /research/v1/{id}/cancel` | Accept multiple IDs. |

### 4. Websets Core (`v0/websets`)

| Command | REST mapping | Highlights |
| --- | --- | --- |
| `exa websets create --name NAME` | `POST /v0/websets` | Flags for `--description`, `--filters @filters.json`, `--seed-urls`, `--tags`, `--metadata`. |
| `exa websets list` | `GET /v0/websets` | Filters: `--cursor`, `--limit`, `--tags`, `--search TEXT`. |
| `exa websets get ID` | `GET /v0/websets/{id}` | `--include items,enrichments`. |
| `exa websets update ID --set @payload.json` | `PATCH /v0/websets/{id}` | Partial updates. |
| `exa websets delete ID` | `DELETE /v0/websets/{id}` | `--force`. |
| `exa websets cancel ID` *(requires new client helper)* | `POST /v0/websets/{id}/cancel` | Cancels all searches/enrichments. |
| `exa websets preview --filters @payload.json` | `POST /v0/websets/preview` | Returns diff/estimated items. |

### 5. Webset Subresources

- **Items** (`/v0/websets/{webset}/items`): `list`, `get`, `delete`. Flags: `--cursor`, `--limit`, `--fields`.
- **Enrichments** (`/v0/websets/{webset}/enrichments`): `create`, `get`, `update`, `delete`, `cancel`. Flags: `--schema`, `--type {summary,qa,custom}`, `--inputs @file`.
- **Searches** (`/v0/websets/{webset}/searches`): `run`, `get`, `cancel`. Parameters: `--query`, `--count`, `--use-previous`, `--filters`.
- **Monitors** (`/v0/monitors` + nested runs):
  - `exa monitors create --name NAME --webset WEBSET_ID --cron "0 * * * *"` etc.
  - `exa monitors list`, `exa monitors get ID`, `exa monitors update`, `exa monitors delete`.
  - `exa monitors runs list ID`, `exa monitors runs get ID RUN_ID`.

### 6. Imports (`/v0/imports`)

| Command | Description |
| --- | --- |
| `exa imports create --webset WEBSET_ID --file FILE` (multi-part upload or presigned URL). Flags: `--type {csv,jsonl}`, `--async`. |
| `exa imports list` with pagination filters. |
| `exa imports get ID`, `exa imports update ID --set status=...`, `exa imports delete ID`. |

### 7. Events & Webhooks

- `exa events list` – Parameters from spec: `--cursor`, `--limit`, `--types webset.created,...`, `--created-before ISO8601`, `--created-after`.
- `exa events get ID`.
- `exa webhooks list/create/get/update/delete` plus `exa webhooks attempts ID --cursor`.

### 8. Misc Helpers

- `exa curl PATH --method METHOD --data JSON` for raw experimentation (pipes to `Exa::Client#request`).
- `exa schemas dump NAME` – print Sorbet schema JSON for a given struct.
- `exa completion` – generate shell completions.

---

## Multi-Account UX

1. CLI resolves config path (flag > env > default) and loads YAML.
2. Account precedence: CLI `--api-key` > `EXA_API_KEY` > stored account `api_key`.
3. When users pass `--account staging --api-key new`, CLI updates config if `--persist` flag set; otherwise, single-run override.
4. Adding accounts via CLI prompts (with `TTY::Prompt` fallback) when flags omitted; tests stub STDIN.

---

## TDD Strategy

1. **Config layer specs**
   - `test/cli/config_store_test.rb`: create temp dir, assert add/remove/use operations mutate YAML; ensure permissions (use `File.stat.mode`).
   - `test/cli/account_resolution_test.rb`: verify precedence between CLI flags, env vars, stored accounts.

2. **Command contract tests (Aruba)**
   - `test/cli/search_commands_test.rb`: run `bundle exec exe/exa search run "foo" --format json`, stub HTTP with `webmock` by pointing `EXA_BASE_URL` to `http://127.0.0.1:4567` and using `WEBrick` fixture or `FakeTransport`.
   - `test/cli/accounts_flow_test.rb`: exercise `accounts:add`, `list`, `use` end-to-end with temporary HOME.
   - `test/cli/research_stream_test.rb`: stub streaming endpoint via local fixture; assert SSE printed gradually.
   - `test/cli/webhooks_test.rb`, `test/cli/events_test.rb`, etc., to cover each resource.

3. **Unit tests for presenters**
   - `test/cli/formatters/table_formatter_test.rb`: ensure column selection.
   - `test/cli/commands/search_options_parser_test.rb`: map CLI flags to `Exa::Types::SearchRequest`.

4. **Golden files**
   - Store fixtures under `test/fixtures/api/*.json` mirroring OpenAPI examples; CLI tests load them to assert output stability (`json`/`table` snapshots).

5. **Guardrails**
   - CI matrix ensures `exe/exa --help` succeeds.
   - Add `bundle exec rubocop` + `bundle exec ruby -c exe/exa` steps.

Workflow: write failing test describing CLI behavior, implement minimal code under `lib/exa/cli`, ensure coverage before moving on. All new commands must have either an Aruba integration spec or a unit spec verifying flag-to-request mapping.

---

## Delivery Checklist for v1.1.0

1. Update `exa-ai-ruby.gemspec`: add `exe/exa` to `spec.executables`, add CLI dependencies.
2. Create CLI skeleton + config store + account commands.
3. Cover search + research commands with tests before implementing others.
4. Iterate resource-by-resource (websets, webhooks, events, imports, monitors).
5. Update README (CLI usage), CHANGELOG (1.1.0), and release automation.

Once CLI + tests land, cut `v1.1.0` and publish gem + GitHub release per instructions.
