# frozen_string_literal: true

require_relative 'page'

module Views
  class Overview < Page
    def a_board
      title = 'Quality Summary'
      tech_debt = folder_filter.tech_debt.map(&:count)
      testcoverage = test_coverage? ? project_coverage : '_'
      elements = {
        elements: [quality_issues],
        critical_info: [{ number: tech_debt.sum, unit: 'Quality Problems'},
                        { number: "#{testcoverage}%", unit: 'Test Coverage'}]
      }
      Element::Board.new(title, elements)
    end

    def b_board
      title = 'Functionality Test Cases'
      elements = [keyword_test_cases]
      Element::Board.new(title, elements)
    end

    def c_board
      title = 'Project Ownership'
      informations = [
        { number: folder_filter.files.count, unit: 'Files'},
        { number: folder_filter.all_methods.count, unit: 'Methods' },
        { number: folder.total_line_credits, unit: 'Line of Code' }
      ]
      elements = {
        elements: [ownership_chart],
        critical_info: informations
      }
      Element::Board.new(title, elements)
    end

    def d_board
      title = 'Project Progress'
      subtitle = 'Here is example message. <br> <div class="title">est</div>'
      elements = [commits_chart('day')]
      Element::Board.new(title, elements)
    end

    def charts_update(params)
      between = params['between'].split('_')
      unit = params['unit'] || 'day'
      [commits_chart(unit, between)]
    end

    def quality_issues
      lines = [{ name: 'Category', number: 'Total' }]
      tech_debt = folder_filter.tech_debt.map(&:count)
      lines.push(name: 'Complex Methods', number: tech_debt[0])
      lines.push(name: 'Code Style Offenses', number: tech_debt[1])
      lines.push(name: 'Unannotated Class', number: tech_debt[2])
      lines.push(name: 'Low TestCoverage File', number: tech_debt[3])
      Element::Bar.new(nil, lines)
    end

    def keyword_test_cases
      lines = [{ name: 'KeyWords', number: 'Total' }]
      max = folder_filter.test_cases.count
      key_words.each do |key_word|
        test_cases = test_cases_with(key_word)
        lines.push(name: key_word, number: test_cases.count, max: max)
      end
      Element::Bar.new(nil, lines)
    end

    def test_cases_with(keyword)
      folder_filter.test_cases.select do |test_case|
        test_case.key_words.include?(keyword)
      end
    end

    def key_words
      folder_filter.test_cases.map(&:key_words).flatten.uniq
    end

    # def ownership_chart
    #   dataset = [{name: 'Contributor', number: 'Percentage'}]
    #   contributors.each do |c|
    #     dataset.push({
    #       name: c.email_id,
    #       number: folder.line_percentage[c.email_id].to_i,
    #       max: 100
    #     })
    #   end
    #   Element::Bar.new('Project Ownership', dataset)
    # end

    def ownership_chart
      labels = ['']
      dataset = contributor_ids.each_with_object({}) do |email_id, result|
        result[email_id] = [folder.line_percentage[email_id].to_i]
      end
      optinos = { title: 'Line of Code Percentage', scales: true, legend: true,
                  color: 'contributors', stacked: true, x_type: 'linear', y_type: 'category' }
      Element::Chart.new(labels, dataset, optinos, 'horizontalBar', 'line_ownership')
    end

    def commits_chart(unit, between = nil)
      all_commits = commits_filter.by(unit, between)
      labels = all_commits.map(&:date)
      dataset = {
        additions: all_commits.map(&:total_addition_credits),
        deletions: all_commits.map { |c| c.total_deletion_credits * -1 }
      }
      max = max_addition(unit, between)
      options = { title: 'productivity progress', scales: true, legend: true,
                  x_type: 'time', time_unit: unit.to_s, color: 'category', stacked: true,
                  y_min: max * -1, y_label: 'line of code' }
      Element::Chart.new(labels, dataset, options, 'bar', 'all_commits')
    end

    def page
      'overview'
    end
  end
end
