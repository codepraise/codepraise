# frozen_string_literal: true

module Views
  module Element
    class SmallTable
      def initialize(title, dataset)
        @title = title
        @dataset = dataset
      end

      def to_element
        "<div class='small_table element'>" \
          "<div class='title'>#{@title}</div>" \
          "#{infos_element}" \
        '</div>'
      end

      def infos_element
        infos_element = @dataset.map do |data|
          info_element(data)
        end.join('')
        "<div class='infos'> #{infos_element} </div>"
      end

      def info_element(info)
        "<div class='info'>" \
          "<div class='name'> #{info[:name]} </div>" \
          "<div class='number'> #{info[:number]} </div>" \
        '</div>'
      end
    end
  end
end
