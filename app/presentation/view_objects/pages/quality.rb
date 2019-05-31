# frozen_string_literal: true

require_relative 'page'

module Views
  class Quality < Page
    TECH_DEBT = ['Complexity Methods', 'CodeStyle Offenses',
                 'Unannotated Files',
                 'Low TestCoverage Files'].freeze

    def a_board
      title = 'Quality Problems'
      elements = quality_problems
      Element::Board.new(title, nil, elements)
    end

    def b_board
      title = 'File Churn'
      elements = [file_churn]
      Element::Board.new(title, nil, elements)
    end

    def c_board
      title = 'Code Quality'
      elements = code_quality
      Element::Board.new(title, nil, elements)
    end

    def d_board
      title = 'Quality Problem Distribution'
      subtitle = 'The dark color mean file with problem.'
      elements = [problem_distribution('complexity_method')]
      Element::Board.new(title, subtitle, elements)
    end

    def charts_update(params)
      type = params['type'] || 'complexity_method'
      email_id = nil
      email_id = params['email_id'] if params['email_id'] != 'total'
      [problem_distribution(type, email_id)]
    end

    def quality_problems
      total_tech_debts = folder_filter.tech_debt.map(&:count)
      contributors.map do |c|
        tech_debts = folder_filter.tech_debt(c.email_id).map(&:count)
        lines = [[]]
        TECH_DEBT.each_with_index do |category, i|
          lines.push(name: category, number: tech_debts[i],
                     max: total_tech_debts[i])
        end
        Element::Bar.new(c.email_id, lines)
      end
    end

    def code_quality
      [complexity_chart, offenses_chart,
       documentation_chart, test_chart]
    end

    def problem_distribution(type, email_id = nil)
      dataset = {}

      folder_traversal(folder, dataset, type, email_id) unless type == 'low_coverage' && !test_coverage?
      Element::Chart.new(nil, [dataset], {}, 'treemap', 'problem_distribution')
    end

    def file_churn
      dataset = folder_filter.files.map do |file|
        { x: file.commits_count, y: file.complexity&.average.to_i,
          r: 10 + (file.commits_count * file.complexity&.average.to_i) / size('commit'),
          title: "#{file.file_path.directory}#{file.file_path.filename}" }
      end
      options = { title: 'File Churn', scales: true, legend: false,
                  x_type: 'linear', tooltips: 'file_churn', axes_label: true,
                  x_label: 'CommitCount', y_label: 'Complexity' }
      Element::Chart.new(nil, dataset, options,
                         'bubble', 'folder_churn')
    end

    def folder_traversal(folder, hash, type, email_id)
      hash['text'] = folder.path
      hash['children'] = []
      if folder.any_subfolders?
        hash['children'] = folder.subfolders.map do |subfolder|
          folder_traversal(subfolder, {}, type, email_id)
        end.reject(&:nil?)
      end
      if folder.any_base_files?
        hash['children'] += files_value(folder.base_files, type, email_id)
      end

      hash unless hash['children'].empty?
    end

    def files_value(files, method, email_id)
      files.map do |file|
        next if email_id && file.line_percentage[email_id].to_i < threshold('ownership')

        {
          text: file.file_path.filename,
          value: send(method, file),
          contributors: file.line_percentage
        }
      end.reject(&:nil?)
    end

    def documentation(file)
      file.has_documentation ? 50 : 100
    end

    def complexity_method(file)
      methods = file.to_h[:methods].select do |method|
        method.complexity > 18
      end
      methods.count.positive? ? 100 : 50
    end

    def offenses(file)
      file.idiomaticity&.offense_count.to_i.positive? ? 100 : 50
    end

    def low_coverage(file)
      return 0 unless test_coverage?

      file.test_coverage&.coverage.to_f > 0.65 ? 100: 50
    end

    def complexity_chart
      dataset = contributors.each.each_with_object({}) do |contributor, result|
        methods = folder_filter.all_methods(contributor.email_id)
        credit = avg_complexity(methods)
        result[contributor.email_id] = [{
          y: credit * -1, x: methods.count,
          r: 10 + (credit * methods.count) / size('method')
        }]
      end
      options = { title: 'simplicity', scales: true, x_type: 'linear', legend: true,
                  axes_label: true, x_label: 'method_count', y_label: 'complexity' }
      Element::Chart.new(nil, dataset, options, 'bubble', 'quality_chart')
    end

    def radius_array
      contributors.each_with_index do |_, i|
        (i + 1) * 10
      end
    end

    def offenses_chart
      dataset = contributors.each_with_object({}) do |contributor, result|
        offenses = folder_filter.total_offenses(contributor.email_id).count
        line_count = productivity_credit['line_credits'][contributor.email_id]
        result[contributor.email_id] = [{
          y: offenses * -1, x: line_count,
          r: 10 + (offenses / 10 * line_count.to_f / size('line'))
        }]
      end
      options = { title: 'clean code style', scales: true, x_type: 'linear',
                  legend: true, axes_label: true, x_label: 'line_count',
                  y_label: 'offense_count'}
      Element::Chart.new(nil, dataset, options, 'bubble', 'offenses_chart')
    end

    def documentation_chart
      dataset = contributors.each_with_object({}) do |contributor, result|
        documentation = quality_credit['documentation_credits'][contributor.email_id].to_i
        methods = folder_filter.all_methods(contributor.email_id)
        result[contributor.email_id] = [{
          y: documentation, x: methods.count,
          r: 10 + (documentation / 5 * methods.count / size('method'))
        }]
      end
      options = { title: 'documentation', scales: true, x_type: 'linear', legend: true,
                  axes_label: true, x_label: 'method_count', y_label: 'documentation_count' }
      Element::Chart.new(nil, dataset, options, 'bubble', 'documentation_chart')
    end

    def test_chart
      dataset = contributors.each_with_object({}) do |contributor, result|
        test = quality_credit['test_credits'][contributor.email_id].to_i
        line_count = productivity_credit['line_credits'][contributor.email_id]
        result[contributor.email_id] = [{
          y: test, x: line_count,
          r: 10 + (test / 5 * line_count / size('line'))
        }]
      end
      options = { title: 'test code', scales: true, x_type: 'linear', legend: true,
                  axes_label: true, x_label: 'line_count', y_label: 'test_code' }
      Element::Chart.new(nil, dataset, options, 'bubble', 'test_chart')
    end

    def page
      'quality'
    end

    def avg_complexity(methods)
      all_complexity = methods.map(&:complexity).reject(&:nil?)
      Math.average(all_complexity)
    end
  end
end
