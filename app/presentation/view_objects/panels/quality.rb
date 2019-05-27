# frozen_string_literal: true

require_relative 'panel'

module Views
  class Quality < Panel
    attr_reader :quality_credit, :folder_filter, :credit_share
    SIMPLICITY = {
      1..10 => 5,
      10..20 => 4,
      20..40 => 3,
      40..60 => 2,
      60..100 => 1,
      100..(1.0 / 0.0) => 0,
      0 => 0
    }.freeze
    TECH_DEBT = {
      complexity: 'Number of Complexity Methods',
      offenses: 'Number of Code Style Offenses',
      documentation: 'Number of Unannotated Files',
      test: 'Number of Low Test Coverage Files'
    }.freeze

    def initialize(appraisal)
      super(appraisal)
      @folder_filter = CodePraise::Decorator::FolderFilter.new(appraisal.folder, contributors)
    end

    def a_board
      title = 'Quality Issues'
      elements = individual_issues
      Board.new(title, nil, nil, elements)
    end

    def b_board
      title = 'Code Quality'
      elements = individual_quality
      Board.new(title, nil, nil, elements)
    end

    def c_board
      elements = [debt_chart('complexity')]
      Board.new(nil, nil, nil, elements)
    end

    def d_board
      title = ''
      elements = [file_churn]
      Board.new(title, nil, nil, elements)
    end

    def sub_charts(params)
      criteria = params['issue'] || 'complexity'
      email_id = nil
      email_id = params['email_id'] if params['email_id'] != 'total'
      [debt_chart(criteria, email_id)]
    end

    def individual_issues
      total_issues = contributors.each_with_object({}) do |contributor, result|
        email_id = contributor.email_id
        result[email_id] = folder_filter.tech_debt(email_id).map(&:count)
      end
      issues = folder_filter.tech_debt.map(&:count)
      TECH_DEBT.values.each_with_index.map do |category, i|
        lines = [{ name: 'Contributor', number: 'Total' }]
        lines += total_issues.map do |k, v|
          {
            name: k,
            line: { width: Math.percentage(v[i], issues[i]), max: issues[i] },
            number: v[i]
          }
        end
        Bars.new(lines, category, true)
      end
    end

    def individual_quality
      [quality_chart('complexity'), offenses_chart,
       documentation_chart, test_chart]
    end

    def debt_chart(criteria, email_id = nil)
      dataset = []
      case criteria
      when 'complexity'
        title = 'Complexity Method Distribution'
        dataset = create_dataset(folder_filter.files_with_complexity_method(email_id), :complexity_methods)
      when 'offenses'
        title = 'Offense Distribution'
        dataset = create_dataset(folder_filter.files_with_offenses(email_id), :offenses_count)
      when 'documentation'
        title = 'Unannotated File Distribution'
        dataset = create_dataset(folder_filter.files_without_documentation(email_id), :documentation_count)
      when 'test'
        title = 'Low Coverage File Distribution'
        dataset = create_dataset(folder_filter.files_with_low_coverage(email_id), :test_coverage)
      end
      Chart.new(nil, dataset, { title: criteria }, 'treemap', 'debt_chart', title)
    end

    def file_churn
      dataset = folder_filter.files.map do |file|
        { x: file.commits_count, y: file.complexity&.average.to_i,
          title: "#{file.file_path.directory}#{file.file_path.filename}" }
      end
      options = { title: 'File Churn', scales: true, legend: false,
                  x_type: 'linear', tooltips: 'file_churn', axes_label: true,
                  x_label: 'CommitCount', y_label: 'Complexity' }
      Chart.new(nil, dataset, options,
                'scatter', 'folder_churn')
    end

    def create_dataset(files, method)
      files_hash = files.group_by do |file|
        file.file_path.directory
      end
      files_hash.keys.each_with_object([]) do |key, result|
        result << {
          text: key,
          children: create_children(files_hash[key], method(method))
        }
      end
    end

    def create_children(files, value_method)
      files.map do |file|
        {
          text: file.file_path.filename,
          value: value_method.call(file)
        }
      end
    end

    def complexity_methods(file)
      file.to_h[:methods].select do |m|
        m.complexity > 18
      end.count
    end

    def offenses_count(file)
      file.idiomaticity.offense_count
    end

    def documentation_count(file)
      1
    end

    def test_coverage(file)
      return file.test_coverage.message unless file.test_coverage.coverage

      coverage = (file.test_coverage.coverage * 100).round
      coverage.zero? ? 10 : coverage
    end

    def quality_chart(category)
      dataset = contributors.each_with_object({}) do |contributor, result|
        methods = folder_filter.all_methods(contributor.email_id)
        credit = category == 'complexity' ? avg_complexity(methods) : avg_simplicity(methods)
        result[contributor.email_id] = [{
          y: credit, x: methods.count, r: 10
        }]
      end
      options = { title: category.to_s, scales: true, x_type: 'linear', legend: true,
                  axes_label: true, x_label: 'method_count', y_label: category.to_s }
      Chart.new(nil, dataset, options, 'bubble', 'quality_chart')
    end

    def offenses_chart
      dataset = contributors.each_with_object({}) do |contributor, result|
        offenses = folder_filter.total_offenses(contributor.email_id).count * -1
        line_count = productivity_credit['line_credits'][contributor.email_id]
        result[contributor.email_id] = [{
          y: offenses, x: line_count, r: (Math.percentage(offenses, line_count).abs + 10) / 2
        }]
      end
      options = { title: 'code style offenses', scales: true, x_type: 'linear',
                  legend: true }
      Chart.new(nil, dataset, options, 'bubble', 'offenses_chart')
    end

    def documentation_chart
      dataset = contributors.each_with_object({}) do |contributor, result|
        documentation = quality_credit['documentation_credits'][contributor.email_id].to_i
        methods = folder_filter.all_methods(contributor.email_id)
        result[contributor.email_id] = [{
          y: documentation, x: methods.count, r: 10
        }]
      end
      options = { title: 'documentation', scales: true, x_type: 'linear', legend: true }
      Chart.new(nil, dataset, options, 'bubble', 'documentation_chart')
    end

    def test_chart
      dataset = contributors.each_with_object({}) do |contributor, result|
        test = quality_credit['test_credits'][contributor.email_id].to_i
        line_count = productivity_credit['line_credits'][contributor.email_id]
        result[contributor.email_id] = [{
          y: test, x: line_count, r: 10
        }]
      end
      options = { title: 'test code', scales: true, x_type: 'linear', legend: true }
      Chart.new(nil, dataset, options, 'bubble', 'test_chart')
    end

    def page
      'quality'
    end

    def avg_complexity(methods)
      all_complexity = methods.map(&:complexity).reject(&:nil?)
      Math.average(all_complexity)
    end

    def avg_simplicity(methods)
      complexity = avg_complexity(methods)
      SIMPLICITY.select { |range| range === complexity }.values.first
    end
  end
end
