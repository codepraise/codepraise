# frozen_string_literal: true

module CodePraise
  module Value
    Elements = Struct.new(:request, :panel) do
      def request_params
        request.query_string.split('&').each_with_object({}) do |query, hash|
          key, value = query.split('=')
          hash[key] = value
        end
      end

      def elements
        panel.charts_update(request_params)
      end

      def to_json
        {
          elements: elements.each_with_object({}) do |element, hash|
            next unless element

            if element.is_a?(Views::Element::Chart)
              hash[element.id] = {
                labels: element.labels,
                dataset: element.dataset,
                options: element.options
              }
            elsif element.is_a?(Views::Element::Table)
              hash[element.id] = {
                tbody: element.tbody
              }
            end
          end
        }.to_json
      end
    end
  end
end
