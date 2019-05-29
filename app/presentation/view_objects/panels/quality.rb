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
    TECH_DEBT = ['Number of Complexity Methods', 'Number of Code Style Offenses',
                 'Number of Unannotated Files',
                 'Number of Low Test Coverage Files'].freeze

    def initialize(appraisal)
      super(appraisal)
      @folder_filter = Decorator::FolderFilter.new(appraisal.folder, contributors)
    end

    def a_board
      title = 'Quality Issues'
      elements = quality_problems
      Board.new(title, nil, nil, elements)
    end

    def b_board
      title = 'File Churn'
      elements = [file_churn]
      Board.new(title, nil, nil, elements)
    end

    def c_board
      title = 'Code Quality'
      elements = individual_quality
      Board.new(title, nil, nil, elements)
    end

    def d_board
      title = 'Issue Distribution'
      elements = [test]
      Board.new(title, nil, nil, elements)
    end

    def sub_charts(params)
      criteria = params['issue'] || 'complexity'
      email_id = nil
      email_id = params['email_id'] if params['email_id'] != 'total'
      [debt_chart(criteria, email_id)]
    end

    def quality_problems
      total_tech_debts = folder_filter.tech_debt.map(&:count)
      contributors.map do |c|
        tech_debts = folder_filter.tech_debt(c.email_id).map(&:count)
        lines = [[]]
        TECH_DEBT.each_with_index do |category, i|
          lines.push(line_hash(category, tech_debts[i], total_tech_debts[i]))
        end
        Bars.new(lines, c.email_id)
      end
    end

    def line_hash(name, number, max)
      {
        name: name,
        line: { width: Math.percentage(number, max), max: max },
        number: number
      }
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
        dataset = create_dataset(folder_filter.files(email_id), :complexity_methods)
      when 'offenses'
        title = 'Offense Distribution'
        dataset = create_dataset(folder_filter.files(email_id), :offenses_count)
      when 'documentation'
        title = 'Unannotated File Distribution'
        dataset = create_dataset(folder_filter.files_without_documentation(email_id), :documentation_count)
      when 'test'
        title = 'Low Coverage File Distribution'
        dataset = create_dataset(folder_filter.files_with_low_coverage(email_id), :test_coverage)
      end
      Chart.new(nil, dataset, { title: criteria }, 'treemap', 'debt_chart', title)
    end

    def test
      dataset = {}
      folder_traversal(folder, dataset)
      Chart.new(nil, [dataset], {}, 'treemap', 'debt_chart', '')
    end

    def file_churn
      dataset = folder_filter.files.map do |file|
        { x: file.commits_count, y: file.complexity&.average.to_i, r: 20,
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
      return 0 unless file.complexity

      file.complexity.average.round
      # file.to_h[:methods].select do |m|
      #   m.complexity > 18
      # end.count
    end

    def offenses_count(file)
      file.idiomaticity.offense_count
    end

    def documentation_count(file)
      1
    end

    def test_coverage(file)
      1
      # return file.test_coverage.message unless file.test_coverage.coverage

      # coverage = (file.test_coverage.coverage * 100).round
      # coverage.zero? ? 10 : coverage
    end

    def folder_traversal(folder, hash)
      hash['text'] = folder.path
      hash['children'] = []
      if folder.any_subfolders?
        hash['children'] = folder.subfolders.map do |subfolder|
          folder_traversal(subfolder, {})
        end
      end
      if folder.any_base_files?
        hash['children'] += file_documentation(folder.base_files)
      end
      hash
    end

    def files_value(files)
      files.map do |file|
        {
          text: file.file_path.filename,
          value: file.complexity&.average.to_i
        }
      end
    end

    def file_documentation(files)
      files.map do |file|
        documentation = file.has_documentation ? 100 : 50
        {
          text: file.file_path.filename,
          value: documentation
        }
      end
    end

    def quality_chart(category)
      dataset = contributors.each_with_object({}) do |contributor, result|
        methods = folder_filter.all_methods(contributor.email_id)
        credit = category == 'complexity' ? avg_complexity(methods) : avg_simplicity(methods)
        result[contributor.email_id] = [{
          y: credit, x: methods.count,
          r: (Math.percentage(credit, methods.count).abs + 10) / 2
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
          y: offenses, x: line_count,
          r: (Math.percentage(offenses, line_count).abs + 10) / 2
        }]
      end
      options = { title: 'code style offenses', scales: true, x_type: 'linear',
                  legend: true, axes_label: true, x_label: 'line_count',
                  y_label: 'offense_count' }
      Chart.new(nil, dataset, options, 'bubble', 'offenses_chart')
    end

    def documentation_chart
      dataset = contributors.each_with_object({}) do |contributor, result|
        documentation = quality_credit['documentation_credits'][contributor.email_id].to_i
        methods = folder_filter.all_methods(contributor.email_id)
        result[contributor.email_id] = [{
          y: documentation, x: methods.count,
          r: (Math.percentage(documentation, methods.count).abs + 10) / 2
        }]
      end
      options = { title: 'documentation', scales: true, x_type: 'linear', legend: true,
                  axes_label: true, x_label: 'method_count', y_label: 'documentation_count' }
      Chart.new(nil, dataset, options, 'bubble', 'documentation_chart')
    end

    def test_chart
      dataset = contributors.each_with_object({}) do |contributor, result|
        test = quality_credit['test_credits'][contributor.email_id].to_i
        line_count = productivity_credit['line_credits'][contributor.email_id]
        result[contributor.email_id] = [{
          y: test, x: line_count,
          r: (Math.percentage(test, line_count).abs + 10) / 2
        }]
      end
      options = { title: 'test code', scales: true, x_type: 'linear', legend: true,
                  axes_label: true, x_label: 'line_count', y_label: 'test_code' }
      Chart.new(nil, dataset, options, 'bubble', 'test_chart')
    end

    def page
      'quality'
    end

    def avg_complexity(methods)
      all_complexity = methods.map(&:complexity).reject(&:nil?)
      Math.average(all_complexity) * -1
    end

    def avg_simplicity(methods)
      complexity = avg_complexity(methods)
      SIMPLICITY.select { |range| range === complexity }.values.first
    end
  end
end
