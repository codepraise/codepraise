# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

module CodePraise
  module Representer
    class Appraisal < Roar::Decorator
      include Roar::JSON

      property :project_name
      property :owner_name
      property :created_at
      property :updated_at
      property :content
      property :state
    end
  end
end
