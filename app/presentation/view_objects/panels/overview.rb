# frozen_string_literal: true

module Views
  class Overview < Panel
    attr_reader :folder_filter, :commits_filter

    def initialize(appraisal)
      super(appraisal)
      @folder_filter = CodePraise::Decorator::FolderFilter.new(folder, contributors)
      @commits_filter = CodePraise::Decorator::CommitsFilter.new(appraisal.commits)
    end

    def a_board
      title = 'Quality Summary'
      elements = [quality_issues]
      tech_debt = folder_filter.tech_debt.map(&:count)
      informations = [{ number: tech_debt.sum, unit: 'Issues' }]
      Board.new(title, nil, informations, elements)
    end

    def b_board
      title = 'Functionality Test Cases'
      elements = [keyword_test_cases]
      Board.new(title, nil, nil, elements)
    end

    def c_board
      title = 'Project Breakdown'
      elements = [ownership_chart]
      informations = [
        { number: folder_filter.files.count, unit: 'Files'},
        { number: folder_filter.all_methods.count, unit: 'Methods' },
        { number: folder.total_line_credits, unit: 'LoC' }
      ]
      Board.new(title, nil, informations, elements)
    end

    def d_board
      title = 'Project Progress'
      elements = [commits_chart('day')]
      Board.new(title, nil, nil, elements)
    end

    def sub_charts(params)
      between = params['between'].split('_')
      unit = params['unit'] || 'day'
      [commits_chart(unit, between)]
    end

    def quality_issues
      lines = [{ name: 'Category', number: 'Total' }]
      tech_debt = folder_filter.tech_debt.map(&:count)
      max = tech_debt.sum
      lines.push(line_hash('Complexity Methods', tech_debt[0], max))
      lines.push(line_hash('Code Style Offenses', tech_debt[1], max))
      lines.push(line_hash('Unannotated Files', tech_debt[2], max))
      lines.push(line_hash('Low Test Coverage Files', tech_debt[3], max))
      Bars.new(lines)
    end

    def keyword_test_cases
      lines = [{ name: 'KeyWords', number: 'Total' }]
      max = folder_filter.test_cases.count
      key_words.each do |key_word|
        test_cases = test_cases_with(key_word)
        lines.push(line_hash(key_word, test_cases.count, max))
      end
      Bars.new(lines)
    end

    def test_cases_with(keyword)
      folder_filter.test_cases.select do |test_case|
        test_case.key_words.include?(keyword)
      end
    end

    def key_words
      folder_filter.test_cases.map(&:key_words).flatten.uniq
    end

    def line_hash(name, number, max)
      { name: name, line: { width: Math.percentage(number, max), max: max }, number: number }
    end

    def ownership_chart
      labels = folder.line_percentage.keys
      dataset = folder.line_percentage.values
      options = { title: 'Project Ownership', scales: true }
      Chart.new(labels, dataset, options, 'bar', 'ownership_chart')
    end

    def commits_chart(unit, between = nil)
      all_commits = commits_filter.by(unit, between)
      labels = all_commits.map(&:date)
      dataset = {
        additions: all_commits.map(&:total_addition_credits),
        deletions: all_commits.map(&:total_deletion_credits)
      }
      options = { title: 'productivity progress', scales: true, legend: true,
                  x_type: 'time', time_unit: unit.to_s }
      Chart.new(labels, dataset, options, 'line', 'all_commits')
    end

    def days_count
      commits_filter.all_days.count
    end

    def first_date
      commits_filter.all_days.first
    end

    def last_date
      commits_filter.all_days.last
    end

    def page
      'overview'
    end
  end
end
