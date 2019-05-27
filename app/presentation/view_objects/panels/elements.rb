# frozen_string_literal: true

module Views
  module Elements
    Chart = Struct.new(:labels, :dataset, :options, :type, :id, :title, :subtitle) do
      def to_element
        if type == 'treemap'
          "<div id='#{id}' class='treemap' data-type='#{type}' " \
          "data-options='#{options.to_json}' " \
          "data-values='#{dataset.to_json}'></div>"
        else
          "<canvas id='#{id}' data-type='#{type}' " \
          "data-labels='#{labels.to_json}' data-values='#{dataset.to_json}' " \
          "data-options='#{options&.to_json}'> </canvase>"
        end
      end
    end

    Table = Struct.new(:thead, :tbody, :id, :title, :subtitle) do
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

    Bars = Struct.new(:lines, :title, :no_first) do
      def to_element
        "<div class='bars element'>" \
          "#{no_first ? '' : first_line(lines[0])}" \
          "#{lines[1..-1].map { |line| line_element(line) }.join('')}" \
        "</div>"
      end

      def first_line(line)
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
        return '' unless line

        "<div class='progress'>" \
          "<div class='progress-bar' role='progressbar' aria-valuenow='0' \
          style='width: #{line[:width]}%' aria-valuemin='0' \
          aria-valuemax='#{line[:max]}'></div>" \
        '</div>'
      end
    end

    SmallTable = Struct.new(:title, :infos) do
      def to_element
        "<div class='small_table element'>" \
          "<div class='title'>#{title}</div>" \
          "#{infos_element}" \
        '</div>'
      end

      def infos_element
        infos_element = infos.map do |info|
          info_element(info)
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

    Board = Struct.new(:title, :subtitle, :informations, :elements)
  end
end
