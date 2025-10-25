# Exa Ruby Client

Work-in-progress Ruby client for the Exa API. See `docs/architecture.md` for the evolving design notes and TDD plan.

## Getting Started

```ruby
require "exa"

client = Exa::Client.new(api_key: ENV.fetch("EXA_API_KEY"))

# Search + contents in one call
resp = client.search.search(
  query: "latest reasoning LLM papers",
  num_results: 5,
  text: {max_characters: 1_000}
)

# Fetch raw contents for known URLs
contents = client.search.contents(urls: ["https://exa.ai"], text: true)

# Answer endpoint with structured search options
answer = client.search.answer(
  query: "Who funds frontier labs?",
  search_options: {num_results: 3, type: Exa::Types::SearchType::Deep}
)

# Research tasks (supports streaming)
research = client.research.create(instructions: "Map robotics labs")
events = client.research.get(research["id"], stream: true)
events.each { |evt| puts evt }

# Websets CRUD
webset = client.websets.create(name: "Competitive Intelligence")

```

Resources available today:

- `client.search` – covers `/search`, `/contents`, `/findSimilar`, `/answer`.
- `client.research` – create/list/get/cancel research tasks, including SSE streaming.
- `client.websets` – minimal CRUD helpers for `/websets`.
