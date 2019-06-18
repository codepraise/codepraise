# frozen_string_literal: true

require_relative 'page'

module Views
  class Productivity < Page
    def a_board
      title = 'Individual Progress'
      elements = productivity_progress_charts('day', nil)
      Element::Board.new(title, elements)
    end

    def b_board
      title = 'Final Contribution Assessment from Blame'
      elements = [summative_assessment, contributor_table]
      Element::Board.new(title, elements)
    end

    def c_board
      title = 'Individual Code Churn on Commits'
      elements = [code_churn]
      Element::Board.new(title, elements)
    end

    def charts_update(params)
      between = params['between']&.split('_')
      unit = params['unit'] || 'day'
      productivity_progress_charts(unit, between)
    end

    def productivity_progress_charts(unit, between)
      elements = []
      contributor_ids.each_with_index do |email_id, index|
        filter_commtis = commits_filter.by(unit, between, email_id)
        labels = filter_commtis.map(&:date)
        dataset = code_churn_hash(filter_commtis)
        y_max = max_addition(unit, between)
        options = { title: "#{email_id} Progress", legend: true,
                    x_type: 'time', time_unit: unit.to_s, y_ticked: true,
                    y_min: y_max * -1, y_max: y_max, color: "multiple_#{index}", stacked: true,
                    y_label: 'line of code' }
        elements << Chart.new(labels, dataset, options, 'bar', "#{email_id}_code_churn")
      end
      elements
    end

    def summative_assessment
      labels = %w[MethodTouched LineCount CommitCount]
      dataset = breakdown_chart_dataset
      options = { title: 'Breakdown Percentage', legend: true, stacked: true,
                  color: 'contributors', x_type: 'linear', y_type: 'category', x_display: 0 }
      Chart.new(labels, dataset, options, 'horizontalBar', 'summative_assessment')
    end

    def breakdown_chart_dataset
      contributor_ids.each_with_object({}) do |email_id, result|
        result[email_id] = [
          Math.percentage(method_touched[email_id], method_touched.values.sum),
          Math.percentage(line_count[email_id], line_credits.values.sum),
          Math.percentage(commits_count[email_id], commits_count.values.sum)
        ]
      end
    end

    def contributor_table
      thead = ['Contributor ID', 'MethodTouched', 'LineCount', 'CommitCount']
      tbody = contributor_ids.each_with_object([]) do |email_id, result|
        result << [email_id, method_touched[email_id], line_count[email_id],
                   commits_count[email_id]]
      end
      Table.new(thead, tbody, 'productivity_table')
    end

    def code_churn
      labels = contributors.map(&:email_id)
      dataset = { addition: [], deletion: [] }
      dataset = labels.each_with_object([]) do |id, result|
        dataset = contributor_ids.each_with_object([]) do |email_id, result|
          result[0] ||= []
          result[1] ||= []
          code_churn = [0, 0]
          code_churn = total_code_churn(commits_filter.by_email_id(email_id)) if email_id == id
          result[0] << code_churn[0]
          result[1] << code_churn[1]
        end
        result << {
          addition: dataset[0],
          deletion: dataset[1]
        }
        # code_churn = total_code_churn(commits_filter.by_email_id(email_id))
        # dataset[:addition] << code_churn[0]
        # dataset[:deletion] << code_churn[1]
      end
      options = { title: 'Code Churn on Commits', scales: true, legend: true,
                  color: 'multiple', y_label: 'line of code', multiple: true  }
      Element::Chart.new(labels, dataset, options, 'bar', 'individual_code_churn')
    end

    def total_code_churn(commits)
      additions = commits.reduce(0) do |pre, commit|
        pre + commit.total_addition_credits
      end
      deletions = commits.reduce(0) do |pre, commit|
        pre + commit.total_deletion_credits
      end
      [additions, deletions]
    end

    def page
      'productivity'
    end
  end
end
