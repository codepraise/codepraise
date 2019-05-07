# frozen_string_literal: true

module CodePraise
  module Value
    Charts = Struct.new(:charts) do
      def to_json
        {
          charts: charts.each_with_object({}) do |chart, hash|
            hash[chart.title] = {
              labels: chart.labels,
              dataset: chart.dataset
            }
          end
        }.to_json
      end
    end
  end
end
