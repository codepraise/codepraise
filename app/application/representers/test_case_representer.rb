# fronze_string_literal: true

require 'roar/decorator'
require 'roar/json'

module CodePraise
  module Representer
    class TestCase < Roar::Decorator
      include Roar::JSON

      property :message
      property :is_functionality
      property :expectation_count
      property :contributors
    end
  end
end
