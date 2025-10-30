# frozen_string_literal: true

require_relative "lib/exa/version"

Gem::Specification.new do |spec|
  spec.name = "exa-ai-ruby"
  spec.version = Exa::VERSION
  spec.authors = ["Vicente Reig Rincon de Arellano"]
  spec.email = ["hey@vicente.services"]

  spec.summary = "Exa API client in Ruby"
  spec.description = "Exa API client in Ruby, Sorbet-friendly and inspired by openai-ruby."
  spec.homepage = "https://github.com/vicentereig/exa-ruby"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("{lib}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }
  spec.files += %w[README.md CHANGELOG.md LICENSE]
  spec.bindir = "exe"
  spec.executables = ["exa"]
  spec.require_paths = ["lib"]

  spec.add_dependency "connection_pool", "~> 2.4"
  spec.add_dependency "sorbet-runtime", "~> 0.5"
  spec.add_dependency "dspy-schema", "~> 1.0", ">= 1.0.1"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "tty-table", "~> 0.12"
  spec.add_dependency "pastel", "~> 0.8"

  spec.add_development_dependency "minitest", "~> 5.22"
  spec.add_development_dependency "rake", "~> 13.2"
  spec.add_development_dependency "rubocop", "~> 1.64"
  spec.add_development_dependency "aruba", "~> 2.2"
  spec.add_development_dependency "webmock", "~> 3.23"
  spec.add_development_dependency "webrick", "~> 1.8"
end
