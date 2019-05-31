# frozen_string_literal: true

require_relative 'page'

module Views
  class Productivity < Page
    def a_board
      title = 'Individual Project Progress'
      elements = contributors.map do |contributor|
        productivity_progress('day', nil, contributor.email_id)
      end
      Element::Board.new(title, nil, elements)
    end

    def b_board
      title = 'Summative Assessment from Blame'
      elements = summative_assessment
      Element::Board.new(title, nil, elements)
    end

    def c_board
      title = 'Individual Code Churn on Commits'
      elements = [code_churn]
      Element::Board.new(title, nil, elements)
    end

    def productivity_progress(unit, between, email_id)
      commtis = commits_filter.by(unit, between, email_id)
      labels = commtis.map(&:date)
      dataset = {
        addition: commtis.map(&:total_addition_credits),
        deletion: commtis.map(&:total_deletion_credits)
      }
      max = max_addition(unit, between)
      options = { title: "#{email_id} Productivity Progress", scales: true, legend: true,
                  x_type: 'time', time_unit: unit.to_s, y_ticked: true,
                  y_min: 0, y_max: max, color: 'colorful' }
      Element::Chart.new(labels, dataset, options, 'line', "#{email_id}_code_churn")
    end

    def summative_assessment
      contributors.map do |c|
        lines = [[]]
        lines.push(number: method_credits(c.email_id),
                   name: 'MethodTouched',
                   max: method_credits.values.sum.round)
        lines.push(number: line_credits(c.email_id),
                   name: 'LineCount', max: line_credits.values.sum.round)
        lines.push(number: commits_filter.by_email_id(c.email_id).count,
                   name: 'CommitCount',
                   max: commits.count)
        Element::Bar.new(c.email_id, lines)
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
      options = { title: 'Code Churn on Commits', scales: true, legend: true }
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
