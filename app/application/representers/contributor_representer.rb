# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

module CodePraise
  module Representer
    # Represents a CreditShare value
    class Contributor < Roar::Decorator
      include Roar::JSON

      property :username
      property :email
      property :email_id
    end
  end
end
