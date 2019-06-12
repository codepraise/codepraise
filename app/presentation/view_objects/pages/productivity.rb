# frozen_string_literal: true

require_relative 'page'

module Views
  class Productivity < Page
    def a_board
      title = 'Individual Progress'
      elements = contributors.map do |contributor|
        productivity_progress('day', nil, contributor.email_id)
      end
      Element::Board.new(title, elements)
    end

    def b_board
      title = 'Final Contribution Assessment from Blame'
      elements = [summative_assessment] + contributor_tables
      Element::Board.new(title, elements)
    end

    def c_board
      title = 'Individual Code Churn on Commits'
      elements = [code_churn]
      Element::Board.new(title, elements)
    end

    def productivity_progress(unit, between, email_id)
      commtis = commits_filter.by(unit, between, email_id)
      labels = commtis.map(&:date)
      dataset = {
        addition: commtis.map(&:total_addition_credits),
        deletion: commtis.map { |c| c.total_deletion_credits * -1 }
      }
      max = max_addition(unit, between)
      options = { title: "#{email_id} Progress", scales: true, legend: true,
                  x_type: 'time', time_unit: unit.to_s, y_ticked: true,
                  y_min: max * -1, y_max: max, color: 'category', stacked: true, y_label: 'line of code' }
      Element::Chart.new(labels, dataset, options, 'bar', "#{email_id}_code_churn")
    end

    # def summative_assessment
    #   contributors.map do |c|
    #     lines = [[]]
    #     lines.push(number: folder_filter.all_methods(c.email_id).count,
    #                name: 'MethodTouched',
    #                max: folder_filter.all_methods.count)
    #     lines.push(number: line_credits(c.email_id),
    #                name: 'LineCount', max: line_credits.values.sum.round)
    #     lines.push(number: commits_filter.by_email_id(c.email_id).count,
    #                name: 'CommitCount',
    #                max: commits.count)
    #     Element::Bar.new(c.email_id, lines)
    #   end
    # end

    def summative_assessment
      labels = ['MethodTouched', 'LineCount', 'CommitCount']
      all_methods = contributor_ids.reduce(0) {|pre, email_id| folder_filter.owned_methods(email_id).count + pre}
      dataset = contributor_ids.each_with_object({}) do |email_id, result|
        result[email_id] = [
          Math.percentage(folder_filter.owned_methods(email_id).count, all_methods),
          Math.percentage(line_credits(email_id), line_credits.values.sum),
          Math.percentage(commits_filter.by_email_id(email_id).count, commits.count)
        ]
      end
      options = { title: 'Productivity Breakdown Percentage', scales: true, legend: true, stacked: true,
                  color: 'contributors', x_type: 'linear', y_type: 'category' }
      Element::Chart.new(labels, dataset, options, 'horizontalBar', "summative_assessment")
    end

    def contributor_tables
      contributor_ids.map do |email_id|
        dataset = [{ name: 'MethodTouched', number: folder_filter.owned_methods(email_id).count },
                   { name: 'LineCount', number: line_credits(email_id) },
                   { name: 'CommitCount', number: commits_filter.by_email_id(email_id).count }]
        Element::SmallTable.new(email_id, dataset)
      end
    end

    def code_churn
      labels = contributors.map(&:email_id)
      dataset = { addition: [], deletion: [] }
      labels.each do |email_id|
        credits = total_credits(commits_filter.by_email_id(email_id))
        dataset[:addition] << credits[0]
        dataset[:deletion] << credits[1]
      end
      options = { title: 'Code Churn on Commits', scales: true, legend: true,
                  color: 'category', y_label: 'line of code' }
      Element::Chart.new(labels, dataset, options, 'bar', 'individual_code_churn')
    end

    def charts_update(params)
      between = params['between']&.split('_')
      unit = params['unit'] || 'day'
      elements = contributors.map do |contributor|
        productivity_progress(unit, between, contributor.email_id)
      end
      elements
    end

    def max_addition(unit, between)
      commits_filter.by(unit, between).map(&:total_addition_credits).max
    end

    def line_hash(name, number, max)
      percentage = Math.percentage(number, max)
      {
        name: name,
        line: { width: percentage, max: max},
        number: "#{number} (#{percentage}%)"
      }
    end

    def page
      'productivity'
    end

    def total_credits(commits)
      additions = commits.reduce(0) do |pre, commit|
        pre + commit.total_addition_credits
      end
      deletions = commits.reduce(0) do |pre, commit|
        pre + commit.total_deletion_credits
      end
      [additions, deletions]
    end
  end
end
