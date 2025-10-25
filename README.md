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

# Sorbet-driven structured outputs
class AnswerShape < T::Struct
  const :headline, String
  const :key_points, T::Array[String]
end

answer = client.search.answer(
  query: "Summarize the latest robotics grants",
  summary: {schema: AnswerShape}
)
answer #=> schema hash generated via dspy-schema so the API enforces your Sorbet type

# Research tasks can stream JSON that matches a Sorbet schema too
class ResearchShape < T::Struct
  const :organization, String
  const :funding_rounds, T::Array[String]
end

research = client.research.create(
  instructions: "Map frontier labs & their funders",
  output_schema: ResearchShape,
  stream: true
)

```

Resources available today:

- `client.search` – covers `/search`, `/contents`, `/findSimilar`, `/answer`.
- `client.research` – create/list/get/cancel research tasks, including SSE streaming.
- `client.websets` – minimal CRUD helpers for `/websets`.
