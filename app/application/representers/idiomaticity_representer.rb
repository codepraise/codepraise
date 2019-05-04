# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

require_relative 'offense_representer'

module CodePraise
  module Representer
    # Represents Idiomaticity Errors
    class Idiomaticity < Roar::Decorator
      include Roar::JSON

      property :offense_ratio
      property :level
      property :offense_count
      collection :offenses, extend: Representer::Offense, class: OpenStruct
    end
  end
end
