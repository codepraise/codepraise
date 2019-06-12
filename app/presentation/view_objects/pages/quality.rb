# frozen_string_literal: true

require_relative 'page'

module Views
  class Quality < Page
    TECH_DEBT = ['Complex Methods', 'CodeStyle Offenses',
                 'Unannotated Files',
                 'Low TestCoverage Files'].freeze

    def a_board
      title = 'Quality Problems'
      elements = [quality_problem_percentage] + quality_problems
      Element::Board.new(title, elements)
    end

    def b_board
      title = 'File Churn'
      elements = [file_churn]
      Element::Board.new(title, elements)
    end

    def c_board
      title = 'Code Quality'
      elements = code_quality
      Element::Board.new(title, elements)
    end

    def d_board
      title = 'Quality Problem Distribution'
      elements = [problem_distribution('complexity_method')]
      Element::Board.new(title, elements)
    end

    def charts_update(params)
      type = params['type'] || 'complexity_method'
      email_id = nil
      email_id = params['email_id'] if params['email_id'] != 'total'
      [problem_distribution(type, email_id)]
    end

    def quality_problems
      # total_tech_debts = folder_filter.tech_debt.map(&:count)
      # contributors.map do |c|
      #   tech_debts = folder_filter.tech_debt(c.email_id).map(&:count)
      #   lines = [[]]
      #   TECH_DEBT.each_with_index do |category, i|
      #     lines.push(name: category, number: tech_debts[i],
      #                max: total_tech_debts[i])
      #   end
      #   Element::Bar.new(c.email_id, lines)
      # end
      contributor_ids.map do |email_id|
        dataset = [{ name: 'Complex Methods', number: individual_tech_debts[email_id][0] },
                   { name: 'CodeStyle Offenses', number: individual_tech_debts[email_id][1] },
                   { name: 'Unannotated Class', number: individual_tech_debts[email_id][2] },
                   { name: 'Low TestCoverage File', number: individual_tech_debts[email_id][3]},
                   { name: 'Line of Ruby Code', number: total_ruby_code(email_id) }]
        Element::SmallTable.new(email_id, dataset)
      end
    end

    def individual_tech_debts
      contributor_ids.each_with_object({}) do |email_id, result|
        result[email_id] = folder_filter.tech_debt(email_id).map(&:count)
      end
    end

    def total_tech_debts
      result = Array.new(4) { |v| v = 0 }
      result.each_with_index do |_, i|
        individual_tech_debts.values.each do |value|
          result[i] += value[i]
        end
      end
      result
    end

    def quality_problem_percentage
      labels = ['Complex Methods', 'CodeStyle Offenses', 'Unannotated Class', 'Low TestCoverage File', 'Line of Ruby Code']
      dataset = contributor_ids.each_with_object({}) do |email_id, result|
        result[email_id] = [
          Math.percentage(individual_tech_debts[email_id][0], total_tech_debts[0]),
          Math.percentage(individual_tech_debts[email_id][1], total_tech_debts[1]),
          Math.percentage(individual_tech_debts[email_id][2], total_tech_debts[2]),
          Math.percentage(individual_tech_debts[email_id][3], total_tech_debts[3]),
          Math.percentage(total_ruby_code(email_id), total_ruby_code)
        ]
      end
      options = { title: 'Individual Quality Problems Percentage', scales: true, legend: true, stacked: true,
                  color: 'contributors', x_type: 'linear', y_type: 'category' }
      Element::Chart.new(labels, dataset, options, 'horizontalBar', "quality_problem")
    end

    def code_quality
      [complexity_chart, documentation_chart,
       offenses_chart, test_chart]
    end

    def problem_distribution(type, email_id = nil)
      dataset = {}

      folder_traversal(folder, dataset, type, email_id) unless type == 'low_coverage' && !test_coverage?
      options = {reverse: false}
      options[:reverse] = true if %w[low_coverage documentation].include?(type)
      Element::Chart.new(nil, [dataset], options, 'treemap', 'problem_distribution')
    end

    def file_churn
      max = 0
      dataset = folder_filter.files.map do |file|
        max = file.commits_count if file.commits_count > max
        { x: file.commits_count, y: file.complexity&.average.to_i,
          r: 10,
          title: "#{file.file_path.directory}#{file.file_path.filename}"}
      end
      options = { title: 'File Churn vs Complexity', scales: true, legend: false,
                  x_type: 'linear', tooltips: 'file_churn', axes_label: true,
                  x_label: 'CommitCount', y_label: 'Complexity', y_ticked: true,
                  y_max: 0, y_min: 0, color: 'same', y_reverse: true }
      options[:line] = {
        data: [{x: max / 2, y: 15, title: '_'}, {x: max, y: 15, title: '_'}]
      }
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
      ruby_files = files.select do |file|
        ruby_file?(file) && (email_id ? owned(file, email_id) : true)
      end
      ruby_files.map do |file|
        {
          text: file.file_path.filename,
          value: send(method, file)
        }
      end.reject(&:nil?)
    end

    def documentation(file)
      # file.comments.select do |c|
      #   c.is_documentation
      # end.count + 1
      file.has_documentation ? 100 : 50
    end

    def complexity_method(file)
      return file.complexity.average if file.to_h[:methods].empty?

      file.to_h[:methods].map(&:complexity).max.round
    end

    def offenses(file)
      file.idiomaticity&.offense_count.to_i + 1
    end

    def low_coverage(file)
      return 0 unless test_coverage?

      (file.test_coverage&.coverage.to_f * 100).round
    end

    def complexity_chart
      max = 0
      max_method_count = 0
      dataset = contributors.each.each_with_object({}) do |contributor, result|
        methods = folder_filter.all_methods(contributor.email_id)
        credit = avg_complexity(methods)
        result[contributor.email_id] = [{
          y: credit, x: methods.count,
          r: 10
        }]
        max_method_count = methods.count if methods.count > max_method_count
        max = credit if credit > max
      end
      options = { title: 'simplicity', scales: true, x_type: 'linear', legend: true,
                  axes_label: true, x_label: 'method count', y_label: 'average complexity',
                  y_ticked: true, y_max: (max+15), y_reverse: true, color: 'contributors'}
      options['line'] = {
        data: [{x:0, y: 15}, {x: max_method_count, y: 15}]
      }
      Element::Chart.new(nil, dataset, options, 'bubble', 'quality_chart')
    end

    def offenses_chart
      max = 0
      dataset = contributor_ids.each_with_object({}) do |email_id, result|
        offenses = folder_filter.total_offenses(email_id).count
        result[email_id] = [{
          y: offenses, x: total_ruby_code(email_id),
          r: 10
        }]
        max = offenses if offenses > max
      end
      options = { title: 'clean code style', scales: true, x_type: 'linear',
                  legend: true, axes_label: true, x_label: 'line of ruby code',
                  y_label: 'offense count', y_ticked: true, y_min: (max+10), y_max: 0,
                  color: 'contributors', y_reverse: true, line: {data: [{x: 0, y:0}]}}
      contributor_ids.each do |email_id|
        options[:line][:data] << {
          x: total_ruby_code(email_id),
          y: (total_ruby_code(email_id) * 0.05).round
        }
      end
      options[:line][:data].sort_by! { |data| data[:x] }
      Element::Chart.new(nil, dataset, options, 'bubble', 'offenses_chart')
    end

    def documentation_chart
      max_files_count = 0
      dataset = contributor_ids.each_with_object({}) do |email_id, result|
        documentation = quality_credit['documentation_credits'][email_id].to_i
        files_count = documentation_files(email_id).count
        result[email_id] = [{
          y: documentation, x: files_count,
          r: 10
        }]
        max_files_count = files_count if files_count > max_files_count
      end
      options = { title: 'documentation', scales: true, x_type: 'linear', legend: true,
                  axes_label: true, x_label: 'ruby file count', y_label: 'documentation count',
                  y_ticked: true, y_min: 0, y_max: max_files_count + 5, color: 'contributors',
                  line: { data: [{ x: 0, y: 0 }] } }
      contributor_ids.each do |email_id|
        options[:line][:data] << {
          x: documentation_files(email_id).count,
          y: documentation_files(email_id).count
        }
      end
      options[:line][:data].sort_by! { |data| data[:x] }
      Element::Chart.new(nil, dataset, options, 'bubble', 'documentation_chart')
    end

    def documentation_files(email_id = nil)
      return file_selector.ruby_files.has_method.unwrap unless email_id

      file_selector.ruby_files.has_method.belong(email_id).unwrap
    end

    def test_chart
      max = 0
      dataset = contributor_ids.each_with_object({}) do |email_id, result|
        test = quality_credit['test_credits'][email_id].to_i
        result[email_id] = [{
          y: test, x: total_ruby_code(email_id),
          r: 10
        }]
        max = test if test > max
      end
      options = { title: 'test contribution', scales: true, x_type: 'linear', legend: true,
                  axes_label: true, x_label: 'line of ruby code', y_label: 'line of test code',
                  y_ticked: true, y_min: 0, y_max: max + 5, color: 'contributors',
                  line: { data: [{x: 0, y: 0}] } }
      contributor_ids.each do |email_id|
        options[:line][:data] << {
          x: total_ruby_code(email_id),
          y: total_ruby_code(email_id)
        }
      end
      options[:line][:data].sort_by! { |data| data[:x] }
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
