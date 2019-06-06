# frozen_string_literal: true

module Views
  module Element
    class Board
      attr_reader :title, :elements

      def initialize(title, subtitle, elements)
        @title = title
        @subtitle = subtitle
        @elements = elements
      end

      def subtitle
        "<a href='#' data-toggle='popover' data-placement='right'" \
        "data-content='#{@subtitle}' data-html='true' data-container='body'> Click here to see the description." \
        '</a>'
      end
    end
  end
end
