# fronze_string_literal: true

require 'roar/decorator'
require 'roar/json'

module CodePraise
  module Representer
    class TestCase < Roar::Decorator
      include Roar::JSON

      property :message
      property :key_words
      property :expectation_count
      property :contributors
      property :top_describe
    end
  end
end
