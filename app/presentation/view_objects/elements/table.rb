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
        "<table class='table table-hover' id='#{id}'>" \
          '<thead> <tr>' \
          "#{thead.map{|head| "<th>#{head}</th>"}.join('')}" \
          '</tr> </thead>' \
          "<tbody> #{tbody_element} </tbody>" \
        '</table>'
      end

      def tbody_element
        tbody.map do |tr|
          '<tr>' \
          "#{tr.map { |td| "<td>#{td}</td>"}.join('')}" \
          '</tr>'
        end.join('')
      end
    end
  end
end
