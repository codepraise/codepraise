# frozen_string_literal: true

source 'https://rubygems.org'
ruby File.read('.ruby-version').strip

# PRESENTATION LAYER
gem 'slim', '~> 4.1'

# APPLICATION LAYER
# Web application related
gem 'figaro', '~> 1.2'
gem 'puma', '~> 5.5'
gem 'roda', '~> 3.50'

# Controllers and services
gem 'dry-monads', '~> 1.4'
gem 'dry-transaction', '~> 0.13'
gem 'dry-validation', '~> 1.5'

# Representers
gem 'multi_json', '~> 1.15'
gem 'roar', '~> 1.1'

# INFRASTRUCTURE LAYER
# Networking
gem 'http', '~> 5.0'

# Pipe operator for method chaining
gem 'chainable_methods', '~> 0.2'

# DEBUGGING
group :development, :test do
  gem 'pry-rescue', '~> 1.5'
  gem 'pry-stack_explorer', '~> 0.6'
  gem 'roda-route_list', '~> 2.1'
end

# TESTING
group :test do
  gem 'headless', '~> 2.3'
  gem 'minitest', '~> 5.14'
  gem 'minitest-rg', '~> 5.2'
  gem 'page-object', '~> 2.3'
  gem 'simplecov', '~> 0.21'
  gem 'vcr', '~> 6.0'
  gem 'watir', '~> 7.0'
  gem 'webmock', '~> 3.14'
end

# QUALITY
group :development, :test do
  gem 'flog', '~> 4.6'
  gem 'reek', '~> 6.0'
  gem 'rubocop', '~> 1.22'
end

# UTILITIES
gem 'pry', '~> 0.14'
gem 'rake', '~> 13.0'

group :development, :test do
  gem 'rerun', '~> 0.13'
end
