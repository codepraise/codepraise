# frozen_string_literal: true

source 'https://rubygems.org'
ruby '2.7.3'

# PRESENTATION LAYER
gem 'slim'

# APPLICATION LAYER
# Web application related
gem 'econfig'
gem 'puma'
gem 'roda'

# Controllers and services
gem 'dry-monads'
gem 'dry-transaction'
gem 'dry-validation'

# Representers
gem 'multi_json'
gem 'roar'

# INFRASTRUCTURE LAYER
# Networking
gem 'http'

# Pipe operator for method chaining
gem 'chainable_methods'

# DEBUGGING
group :development, :test do
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
  gem 'roda-route_list'
end

# TESTING
group :test do
  gem 'headless'
  gem 'minitest'
  gem 'minitest-rg'
  gem 'page-object'
  gem 'simplecov'
  gem 'vcr'
  gem 'watir'
  gem 'webmock'
end

# QUALITY
group :development, :test do
  gem 'flog'
  gem 'reek'
  gem 'rubocop'
end

# UTILITIES
gem 'pry'
gem 'rake'

group :development, :test do
  gem 'rerun'
end
