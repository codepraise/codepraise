# frozen_string_literal: true

module Views
  module Element
    class Bar
      attr_reader :dataset, :title

      def initialize(title, dataset)
        @title = title
        @dataset = dataset
      end

      def lines
        @dataset.map do |data|
          next if data.empty?

          {
            name: data[:name],
            line: line_hash(data),
            number: data[:number]
          }
        end
      end

      def line_hash(data)
        return {} unless data[:max]

        percentage = Math.percentage(data[:number], data[:max])
        {
          width: percentage, max: data[:max]
        }
      end

      def to_element
        "<div class='bars element'>" \
          "#{first_line(lines[0])}" \
          "#{lines[1..-1].map { |line| line_element(line) }.join('')}" \
        '</div>'
      end

      def first_line(line)
        return '' unless line

        "<div class='bar first'>" \
          "<div class='name'>#{line[:name]}</div>" \
          "<div class='line'>#{progress_bar(line[:line])}</div>" \
          "<div class='number'>#{line[:number]}</div>" \
        '</div>'
      end

      def line_element(line)
        return '' unless line

        "<div class='bar'>" \
          "<div class='name'>#{line[:name]}</div>" \
          "<div class='line'>#{progress_bar(line[:line])}</div>" \
          "<div class='number'>#{line[:number]}</div>" \
        '</div>'
      end

      def progress_bar(line)
        return '' if line.empty?

        "<div class='progress'>" \
          "<div class='progress-bar' role='progressbar' aria-valuenow='0' \
          style='width: #{line[:width]}%' aria-valuemin='0' \
          aria-valuemax='#{line[:max]}'></div>" \
        '</div>'
      end
    end
  end
end
