# frozen_string_literal: true

module Views
  module Element
    class Treemap
      attr_reader :thead, :tbody, :id

      def initialize(dataset, max_values, id)
        @id = id
        @dataset = dataset
        @max_values = max_values
      end

      def to_element
        "<div class='treemap' id='#{@id}'" \
        " data-values='#{@dataset.to_json}' data-max='#{@max_values}'>" \
        '</div>'
      end
    end
  end
end
