# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

module CodePraise
  module Representer
    # Represents folder summary about repo's folder
    class MethodComplexity < Roar::Decorator
      include Roar::JSON

      property :name
      property :complexity
      property :contributors
    end
  end
end
