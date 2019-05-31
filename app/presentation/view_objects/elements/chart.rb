# frozen_string_literal: true

module Views
  module Element
    class Chart
      attr_reader :labels, :dataset, :options, :type, :id

      def initialize(labels, dataset, options, type, id)
        @labels = labels
        @dataset = dataset
        @options = options
        @type = type
        @id = id
      end

      def to_element
        if @type == 'treemap'
          treemap
        else
          canvas
        end
      end

      def canvas
        "<canvas id='#{id}' data-type='#{type}' " \
        "data-labels='#{labels.to_json}' data-values='#{dataset.to_json}' " \
        "data-options='#{options&.to_json}'> </canvase>"
      end

      def treemap
        "<div id='#{id}' class='treemap' data-type='#{type}' " \
        "data-options='#{options.to_json}' " \
        "data-values='#{dataset.to_json}'></div>"
      end
    end
  end
end
