# frozen_string_literal: true

module Views
  module Element
    class Board
      attr_reader :title, :elements

      def initialize(title, elements)
        @title = title
        @elements = elements
      end

      def subtitle(title, content)
        "<a href='#' data-toggle='popover' data-placement='right'" \
        "data-content='#{content}' title='#{title}' data-html='true' data-container='body'>" \
        "<i class='fas fa-info-circle'></i> Description." \
        '</a>'
      end
    end
  end
end
