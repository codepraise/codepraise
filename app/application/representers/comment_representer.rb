# frozen_string_literal: true

# Represents essential Repo information for API output
module CodePraise
  module Representer
    class Comment < Roar::Decorator
      include Roar::JSON

      property :type
      property :is_documentation
      property :contributors
    end
  end
end
