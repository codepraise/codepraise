# frozen_string_literal: true

module Views
  module Element
    class Table
      attr_reader :thead, :tbody, :id

      def initialize(thead, tbody, id)
        @thead = thead
        @tbody = tbody
        @id = id
      end

      def to_element
        "<table class='table table-hover table-sm' id='#{id}'>" \
          '<thead> <tr>' \
          "#{thead_elements}" \
          '</tr> </thead>' \
          "<tbody> #{tbody_element} </tbody>" \
        '</table>'
      end

      def thead_elements
        thead.map { |th| "<th scope='col'>#{th}</th>" }.join('')
      end

      def tbody_element
        @tbody.map do |tds|
          "<tr> #{tds_element(tds)} </tr>"
        end.join('')
      end

      def tds_element(tds)
        tds.each_with_index.map do |td, i|
          if i.zero?
            "<th scope='row'>#{td}</th>"
          else
            "<td>#{td}</td>"
          end
        end.join('')
      end
    end
  end
end
