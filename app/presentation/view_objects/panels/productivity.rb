# frozen_string_literal: true

require_relative 'panel'

module Views
  class Productivity < Panel
    attr_reader :commits_filter, :productivity_credit, :contributors

    def initialize(appraisal)
      super(appraisal)
      @commits_filter = CodePraise::Decorator::CommitsFilter.new(appraisal.commits)
      @productivity_credit = appraisal.folder.credit_share.productivity_credit
    end

    def a_board
      title = 'Individual Project Progress'
      elements = contributors.map do |contributor|
        productivity_progress('day', nil, contributor.email_id)
      end
      Board.new(title, nil, nil, elements)
    end

    def b_board
      title = 'Summative Assessment'
      elements = [summative_asessment]
      Board.new(title, nil, nil, elements)
    end

    def c_board
      title = 'Individual Code Churn'
      elements = [code_churn]
      Board.new(title, nil, nil, elements)
    end

    def sub_charts(params)
      between = params['between']&.split('_')
      unit = params['unit'] || 'day'
      elements = contributors.map do |contributor|
        productivity_progress(unit, between, contributor.email_id)
      end
      elements
    end

    def productivity_progress(unit, between, email_id)
      commtis = commits_filter.by(unit, between, email_id)
      labels = commtis.map(&:date).map { |date| date }
      dataset = {
        addition: commtis.map(&:total_addition_credits),
        deletion: commtis.map(&:total_deletion_credits)
      }
      max = max_addition(unit, between)
      options = { title: "#{email_id} Code Churn", scales: true, legend: true,
                  x_type: 'time', time_unit: unit.to_s, y_ticked: true,
                  y_min: 0, y_max: max, color: 'colorful' }
      Chart.new(labels, dataset, options, 'line', "#{email_id}_code_churn")
    end

    def max_addition(unit, between)
      commits_filter.by(unit, between).map(&:total_addition_credits).max
    end

    def summative_asessment
      thead = ['Contributor', 'MethodCount', 'LineCount', 'CommitCount']
      body = contributors.map do |contributor|
        tbody(contributor.email_id)
      end
      Table.new(thead, body, 'summative_assessment')
    end

    def code_churn
      labels = contributors.map(&:email_id)
      dataset = { addition: [], deletion: [] }
      labels.each do |email_id|
        credits = total_credits(commits_filter.by_email_id(email_id))
        dataset[:addition] << credits[0]
        dataset[:deletion] << credits[1]
      end
      options = { title: 'Individual Code Churn', scales: true, legend: true }
      Chart.new(labels, dataset, options, 'bar', 'individual_code_churn')
    end

    def tbody(email_id)
      method_count = @productivity_credit['method_credits'][email_id].to_i.round
      total_method = @productivity_credit['method_credits'].values.sum
      line_count = @productivity_credit['line_credits'][email_id].to_i.round
      total_line = @productivity_credit['line_credits'].values.sum
      user_commits = commits_filter.by_email_id(email_id)
      total_commits = commits.count
      [email_id, "#{method_count} (#{Math.percentage(method_count, total_method)}%)",
       "#{line_count} (#{Math.percentage(line_count, total_line)}%)",
       "#{user_commits.count} (#{Math.percentage(user_commits.count, total_commits)}%)",]
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

    def page
      'productivity'
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
  end
end
