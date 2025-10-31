# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development do
  gem "bundler", "~> 2.5"
  gem "rake", "~> 13.2"
  gem "minitest", "~> 5.22"
  gem "rubocop", "~> 1.64", require: false
end

group :test do
  gem "aruba", "~> 2.3"
  gem "webmock", "~> 3.25"
  gem "webrick", "~> 1.8"
end

group :development, :test do
  gem "async", "~> 2.6"
  gem "async-http", "~> 0.92"
end
