# frozen_string_literal: true

module Views
  module Element
    class Board
      attr_reader :title, :subtitle, :elements

      def initialize(title, subtitle, elements)
        @title = title
        @subtitle = subtitle
        @elements = elements
      end
    end
  end
end
