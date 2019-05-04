# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

require_relative 'method_complexity_representer'

module CodePraise
  module Representer
    # Represents folder summary about repo's folder
    class Complexity < Roar::Decorator
      include Roar::JSON

      property :average
      property :level
      collection :method_complexities, extend: Representer::MethodComplexity,
                                       class: OpenStruct
    end
  end
end
