# frozen_string_literal: true

require_relative 'page'

module Views
  class Quality < Page
    TECH_DEBT = ['Complex Methods', 'CodeStyle Offenses',
                 'Unannotated Files',
                 'Low TestCoverage Files'].freeze

    def a_board
      title = 'Quality Problems'
      elements = [quality_problem_percentage, quality_problems]
      Element::Board.new(title, elements)
    end

    def b_board
      title = 'Risky Files'
      elements = [file_churn]
      Element::Board.new(title, elements)
    end

    def c_board
      title = 'Individual Code Quality'
      elements = [complexity_chart, documentation_chart,
                  offenses_chart, test_chart]
      Element::Board.new(title, elements)
    end

    def d_board
      title = 'Quality Problem Distribution'
      elements = [problem_location('complexity_method')]
      Element::Board.new(title, elements)
    end

    def charts_update(params)
      type = params['type'] || 'complexity_method'
      email_id = nil
      email_id = params['email_id'] if params['email_id'] != 'total'
      [problem_location(type, email_id)]
    end

    def quality_problems
      thead = ['Contributor ID', 'Complex Methods', 'CodeStyle Offenses', 'Unannotated Class',
               'Low TestCoverage File', 'Line of Ruby Code']
      tbody = contributor_ids.each_with_object([]) do |email_id, result|
        result << [email_id] + quality_problems_hash[email_id] + [total_ruby_code(email_id)]
      end
      Table.new(thead, tbody, 'quality_problems_table')
    end

    def quality_problem_percentage
      labels = ['Complex Methods', 'CodeStyle Offenses', 'Unannotated Class', 'Low TestCoverage File', 'Line of Ruby Code']
      dataset = contributor_ids.each_with_object({}) do |email_id, result|
        result[email_id] = [
          Math.percentage(quality_problems_hash[email_id][0], total_qualit_problems[0]),
          Math.percentage(quality_problems_hash[email_id][1], total_qualit_problems[1]),
          Math.percentage(quality_problems_hash[email_id][2], total_qualit_problems[2]),
          Math.percentage(quality_problems_hash[email_id][3], total_qualit_problems[3]),
          Math.percentage(total_ruby_code(email_id), total_ruby_code)
        ]
      end
      options = { title: 'Percentage of Individual Quality Problems', scales: true, legend: true, stacked: true,
                  color: 'contributors', x_type: 'linear', y_type: 'category', x_display: 0 }
      Chart.new(labels, dataset, options, 'horizontalBar', "quality_problem")
    end

    def problem_location(type, email_id = nil)
      dataset = {}

      folder_traversal(folder, dataset, type, email_id) unless type == 'low_coverage' && !test_coverage?
      options = {reverse: false}
      options[:reverse] = true if %w[low_coverage documentation].include?(type)
      Chart.new(nil, [dataset], options, 'treemap', 'problem_distribution')
    end

    def folder_traversal(folder, hash, type, email_id)
      hash[:text] = folder.path
      hash[:children] = []
      if folder.any_base_files?
        hash[:children] += files_value(folder.base_files, type, email_id)
      end
      if folder.any_subfolders?
        hash[:children] = folder.subfolders.map do |subfolder|
          folder_traversal(subfolder, {}, type, email_id)
        end.reject(&:nil?)
      end
      hash unless hash[:children].empty?
    end

    def files_value(files, method, email_id)
      ruby_files = file_selector(files).ruby_files
        .owned(email_id, threshold('ownership')).unwrap
      ruby_files.map do |file|
        {
          text: file.file_path.filename,
          value: send(method, file)
        }
      end.reject { |f| f[:value].zero? }
    end

    def documentation(file)
      file.has_documentation ? 100 : 50
    end

    def complexity_method(file)
      return file.complexity.average.round if file.to_h[:methods].empty?

      file.to_h[:methods].map(&:complexity).max.round
    end

    def offenses(file)
      file.idiomaticity&.offense_count.to_i
    end

    def low_coverage(file)
      return nil unless test_coverage?

      (file.test_coverage&.coverage.to_f * 100).round
    end

    def file_churn
      max_commits = 0
      dataset = ruby_files.map do |file|
        max_commits = file.commits_count if file.commits_count > max_commits
        { x: file.commits_count, y: complexity(file),
          r: 10,
          title: file_path(file) }
      end
      line_data = [{ x: max_commits / 2, y: 15 }, { x: max_commits, y: 15 }]
      options =
        bubble_chart_options('File Churn vs Complexity', ['ComitCount', 'File Complexity'],
                             [0, 0], true, 'same', line_data, 'file_churn', 'rect')
      Chart.new(nil, {'ruby file' => dataset}, options,
                'bubble', 'folder_churn')
    end

    def complexity_chart
      max_complexity = individual_complexity.values.max
      max_method_count = method_touched.values.max
      dataset = complexity_dataset
      line_data = [{ x:0, y: 15 }, { x: max_method_count, y: 15 }]
      options = bubble_chart_options('simplicity', ['method count', 'average complexity'],
                                     [max_complexity + 15, 0], true, 'contributors', line_data)
      Chart.new(nil, dataset, options, 'bubble', 'quality_chart')
    end

    def complexity_dataset
      contributor_ids.each.each_with_object({}) do |email_id, result|
        result[email_id] = [{
          y: individual_complexity[email_id],
          x: method_touched[email_id], r: 10
        }]
      end
    end

    def offenses_chart
      max_offense = offense_dataset[:max_offense]
      max_code = offense_dataset[:max_code]
      dataset = offense_dataset[:dataset]
      line_data = [{ x: 0, y: 0 }, { x: max_code, y: 0 }]
      options = bubble_chart_options('clean code style', ['line of ruby code', 'offense count'],
                                     [max_offense + 10, 0], true, 'contributors', line_data)
      options[:line][:data].sort_by! { |data| data[:x] }
      Chart.new(nil, dataset, options, 'bubble', 'offenses_chart')
    end

    def offense_dataset
      max_offense = 0
      max_code = 0
      dataset = contributor_ids.each_with_object({}) do |email_id, result|
        offenses = folder_filter.total_offenses(email_id).count
        ruby_code = total_ruby_code(email_id)
        result[email_id] = [{
          y: offenses, x: ruby_code,
          r: 10
        }]
        max_offense = offenses if offenses > max_offense
        max_code = ruby_code if ruby_code > max_code
      end
      {
        max_offense: max_offense, max_code: max_code, dataset: dataset
      }
    end

    def documentation_chart
      dataset = documentation_dataset
      line_data = [{ x: 0, y:0 }]
      contributor_ids.each do |email_id|
        line_data << {
          x: documentation_files(email_id).count,
          y: documentation_files(email_id).count
        }
      end
      line_data.sort_by! { |data| data[:x] }
      options = bubble_chart_options('documentation', ['ruby file count', 'documentation count'],
                                     [0, 0], false, 'contributors', line_data)
      Chart.new(nil, dataset, options, 'bubble', 'documentation_chart')
    end

    def documentation_dataset
      contributor_ids.each_with_object({}) do |email_id, result|
        documentation = documentation_credits[email_id].to_i
        files_count = documentation_files(email_id).count
        result[email_id] = [{
          y: documentation, x: files_count,
          r: 10
        }]
      end
    end

    def test_chart
      dataset = test_dataset
      line_data = [{ x: 0, y: 0 }]
      contributor_ids.each do |email_id|
        line_data << {
          x: total_ruby_code(email_id),
          y: total_ruby_code(email_id)
        }
      end
      line_data.sort_by! { |data| data[:x] }
      options = bubble_chart_options('test contribution', ['line of ruby code', 'line of test code'],
                                     [0, 0], false, 'contributors', line_data)
      Chart.new(nil, dataset, options, 'bubble', 'test_chart')
    end

    def test_dataset
      contributor_ids.each_with_object({}) do |email_id, result|
        test = test_credits[email_id].to_i
        result[email_id] = [{
          y: test, x: total_ruby_code(email_id) - test,
          r: 10
        }]
      end
    end

    def page
      'quality'
    end

    def quality_problems_hash
      contributor_ids.each_with_object({}) do |email_id, result|
        result[email_id] = folder_filter.quality_problems(email_id)
      end
    end

    def total_qualit_problems
      result = Array.new(4) { |v| v = 0 }
      result.each_with_index do |_, i|
        quality_problems_hash.values.each do |value|
          result[i] += value[i]
        end
      end
      result
    end

    def bubble_chart_options(title, labels, y_scale, y_reverse, color, line_data, tooltips = nil, point = 'circle')
      { scales: true, x_type: 'linear', legend: true, x_label: labels[0],
        y_label: labels[1], y_max: y_scale[0], y_min: y_scale[1], y_reverse: y_reverse,
        color: color, line: { data: line_data }, tooltips: tooltips, title: title, point: point }
    end

    def documentation_credits
      quality_credit['documentation_credits']
    end

    def individual_complexity
      contributor_ids.each_with_object({}) do |email_id, result|
        complexity = file_selector.to_methods.unwrap
          .reduce(0) do |pre, method|
            pre + method.complexity * (method.line_percentage[email_id].to_f / 100)
          end
        result[email_id] =
          Math.divide(complexity, method_touched[email_id])
      end
    end

    def documentation_files(email_id = nil)
      return file_selector.ruby_files.has_method.unwrap unless email_id

      file_selector.ruby_files.has_method.belong(email_id).unwrap
    end

    def test_credits
      quality_credit['test_credits']
    end
  end
end
