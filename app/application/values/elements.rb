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
        panel.sub_charts(request_params)
      end

      def to_json
        {
          elements: elements.each_with_object({}) do |element, hash|
            next unless element

            if element.is_a?(Views::Panel::Chart)
              hash[element.id] = {
                labels: element.labels,
                dataset: element.dataset,
                options: element.options,
                title: element.title,
                subtitle: element.subtitle
              }
            elsif element.is_a?(Views::Panel::Table)
              hash[element.id] = {
                tbody: element.tbody,
                title: element.title
              }
            end
          end
        }.to_json
      end
    end
  end
end
