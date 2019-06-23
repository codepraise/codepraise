# frozen_string_literal: true

require_relative 'page'

module Views
  class Productivity < Page
    def a_board
      title = 'Individual Production Process'
      elements = productivity_progress_charts('day', nil)
      Element::Board.new(title, elements)
    end

    def b_board
      title = 'Final Production Code'
      elements = [summative_assessment, contributor_table]
      Element::Board.new(title, elements)
    end

    def c_board
      title = 'Individual Code Churn in Production Process'
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
      labels = %w[MethodTouched LineCredit CommitCount TotalAdditions TotalDeletions]
      dataset = breakdown_chart_dataset
      options = { title: 'Percentage of contribution in different measurement', legend: true, stacked: true,
                  color: 'contributors', x_type: 'linear', y_type: 'category', x_display: 0 }
      Chart.new(labels, dataset, options, 'horizontalBar', 'summative_assessment')
    end

    def breakdown_chart_dataset
      contributor_ids.each_with_object({}) do |email_id, result|
        result[email_id] = [
          Math.percentage(method_touched[email_id], method_touched.values.sum),
          Math.percentage(line_count[email_id], line_credits.values.sum),
          Math.percentage(commits_count[email_id], commits_count.values.sum),
          Math.percentage(total_addition_credits[email_id], total_addition_credits.values.sum),
          Math.percentage(total_deletion_credits[email_id], total_deletion_credits.values.sum),
          Math.percentage(production_ratio[email_id], production_ratio.values.sum)
        ]
      end
    end

    def contributor_table
      thead = ['Contributor', 'MethodTouched', 'LineCredit', 'CommitCount', 'TotalAdditions', 'TotalDeletions']
      tbody = contributor_ids.each_with_object([]) do |email_id, result|
        result << [email_id, method_touched[email_id], line_count[email_id].round,
                   commits_count[email_id], total_addition_credits[email_id],
                   total_deletion_credits[email_id]]
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
      options = { title: 'Total Code Churn', scales: true, legend: true,
                  color: 'multiple', y_label: 'line of code', multiple: true  }
      Chart.new(labels, dataset, options, 'bar', 'individual_code_churn')
    end

    def production_rate
      dataset = contributor_ids.each_with_object({}) do |email_id, result|
        result[email_id] = [{
          x: total_addition_credits[email_id],
          y: Math.percentage(line_count[email_id], total_addition_credits[email_id]),
          r: 10
        }]
      end
      options = { scales: true, x_type: 'linear', legend: true, x_label: 'total additions', y_label: 'production rate',
                  color: 'contributors', y_max: 100, title: 'Production Rate vs Total Additions', point: 'circle' }
      Chart.new(nil, dataset, options, 'bubble', 'production_rate')
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

    def production_ratio
      @production_ratio = contributor_ids.each_with_object({}) do |email_id, result|
        result[email_id] = Math.percentage(line_count[email_id], total_addition_credits[email_id])
      end
    end

    def page
      'productivity'
    end
  end
end
