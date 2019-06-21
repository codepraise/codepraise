# frozen_string_literal: true

module Views
  module Element
    class Board
      attr_reader :title, :elements

      def initialize(title, elements)
        @title = title
        @elements = elements
      end

      def subtitle(content)
        return nil if content == ''

        "<a href='#' data-toggle='popover' data-placement='right'" \
        "data-content='#{content}' data-html='true' data-container='body'>" \
        "<i class='fas fa-info-circle'></i>" \
        '</a>'
      end
    end
  end
end
