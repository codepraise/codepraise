# frozen_string_literal: true

require_relative 'panel'

module Views
  class ProductivityPanel < Panel
    attr_reader :commits_filter, :productivity_credit, :contributors

    def initialize(appraisl)
      super(appraisl)
      @commits_filter = CodePraise::Value::CommitsFilter.new(appraisl.commits)
      @productivity_credit = appraisl.folder.credit_share.productivity_credit
      @contributors = appraisl.folder.credit_share.contributors
    end

    def table
      thead = ['Contributor', 'MethodCount', 'LineCount',
               'LinePerMethod', 'CommitCount', 'TotalAddition', 'TotalDeletion']
      Table.new(thead, contributors_credits.values)
    end

    def contributors_credits
      @contributors.each_with_object({}) do |contributor, result|
        result[contributor.email_id] = tbody(contributor.email_id)
      end
    end

    def tbody(email_id)
      method_count = @productivity_credit['method_credits'][email_id].to_i.round
      line_count = @productivity_credit['line_credits'][email_id].to_i.round
      commits = commits_filter.select_by_contributor(email_id)
      additions = commits.map(&:total_addition_credits).sum
      deletion = commits.map(&:total_deletion_credits).sum
      [email_id, method_count, line_count, divided(line_count, method_count),
       commits.count, additions, deletion]
    end

    def sub_charts(number)
      [line_charts_weeks(number), contributors_chart(number)]
    end

    def main_chart
      bar_chart_weeks
    end

    def line_charts_weeks(number)
      commits = commits_in_week(number)
      labels = commits.map(&:date).map { |date| date_format(date) }
      dataset = {
        addition: commits.map(&:total_addition_credits),
        deletion: commits.map(&:total_deletion_credits)
      }
      Chart.new(labels, dataset, 'line_charts')
    end

    def bar_chart_weeks
      labels = commits_by_week.keys
      dataset = { additions: [], deletions: []}
      commits_by_week.values.each_with_index do |commits, index|
        dataset[:additions] << commits.map(&:total_addition_credits).sum
        dataset[:deletions] << commits.map(&:total_deletion_credits).sum
      end
      Chart.new(labels, dataset, 'main_chart')
    end

    def contributors_chart(number)
      labels = contributors.map(&:email_id)
      dataset = { additions: [], deletions: []}
      contributors.each_with_object(Hash.new([])) do |contributor, result|
        contributor_commits = commits_in_week(number).map do |commit|
          commit.select(contributor.email_id)
        end.flatten
        dataset[:additions] << contributor_commits.map(&:total_addition_credits).sum
        dataset[:deletions] << contributor_commits.map(&:total_deletion_credits).sum
      end
      Chart.new(labels, dataset, 'contributors_chart')
    end

    def total_weeks
      @commits_filter.weeks.length
    end

    def type
      'productivity'
    end

    def commits_in_week(number)
      commits_by_week.values[number]
    end

    def commits_by_week
      return @commits_by_week if @commits_by_week

      commits = @commits_filter.group_by_week.reject do |_, v|
        v.empty?
      end
      commits_size = commits.length / 6

      return resize_commits(commits_size) if commits_size > 1

      @commits_by_week ||= commits
    end

    def date_format(date)
      date = Time.parse(date) if date.is_a?(String)
      date.strftime('%m/%d %H:%M')
    end

    def resize_commits(number)
      @commits_filter.group_by_week(number).reject do |_, v|
        v.empty?
      end
    end
  end
end
