# frozen_string_literal: true

require_relative 'page'

module Views
  class Functionality < Page
    def a_board
      title = 'Test Cases with Different KeyWords'
      subtitle = 'click the bar to change other charts.'
      elements = [keywords_chart]
      Element::Board.new(title, subtitle, elements)
    end

    def b_board
      title = 'Individual Contribution'
      subtitle = '(test case count)'
      elements = [key_word_contributor_chart]
      Element::Board.new(title, subtitle, elements)
    end

    def c_board
      title = 'Test Case Detail'
      subtitle = ''
      elements = [test_cases_detail_table]
      Element::Board.new(title, subtitle, elements)
    end

    def charts_update(params)
      keyword = params['keyword']
      [key_word_contributor_chart(keyword),
       test_cases_detail_table(keyword)]
    end

    def keywords_chart
      labels = key_words
      dataset = labels.map do |label|
        test_cases_with(label).count
      end
      options = { title: 'KeyWord Test Cases', scales: true }
      Element::Chart.new(labels, dataset,
                         options, 'bar', 'keywords')
    end

    def key_word_contributor_chart(key_word = nil)
      key_word ||= key_words[0]
      labels = contributors.map(&:email_id)
      dataset = []
      contributors.each do |contributor|
        dataset << test_cases_with(key_word).select do |test_case|
          max = test_case.contributors.values.max
          test_case.contributors[contributor.email_id] == max
        end.count
      end
      options = { title: "#{key_word} Contribution", scales: true}
      Element::Chart.new(labels, dataset,
                         options, 'bar', 'key_word_contributor')
    end

    def test_cases_detail_table(key_word = nil)
      key_word ||= key_words[0]
      thead = %w[KeyWord Describe Message ExpectationCount Contributors]
      tbody = test_cases_with(key_word).map do |test_case|
        [key_word, test_case.top_describe, test_case.message,
         test_case.expectation_count,
         contributors_string(test_case.contributors) ]
      end
      Element::Table.new(thead, tbody, 'test_cases_detail')
    end

    def key_words
      test_cases.map(&:key_words).flatten.uniq
    end

    def test_cases
      folder_filter.test_cases
    end

    def test_cases_with(keyword)
      test_cases.select do |test_case|
        test_case.key_words.include?(keyword)
      end
    end

    def contributors_string(contributors)
      contributors.map do |k, v|
        "#{k}: #{v}"
      end.join('')
    end

    def page
      'functionality'
    end
  end
end
