# frozen_string_literal: true

require_relative 'panel'

module Views
  class ProductivityPanel < Panel

    attr_reader :commits_filter

    def initialize(appraisl)
      super(appraisl)
      @commits_filter = CodePraise::Value::CommitsFilter.new(appraisl.commits)
    end

    def line_charts_weeks(start_week, end_week)
      commits = @commits_filter.select_by_week(start_week, end_week)
      labels = commits.map(&:date).map { |date| date_format(date) }
      dataset = {
        addition: commits.map(&:total_additions),
        deletion: commits.map(&:total_deletions)
      }
      Chart.new(labels, dataset)
    end

    def bar_chart_weeks
      labels = commits_by_week.keys
      result = { additions: [], deletions: []}
      commits_by_week.values.each_with_index do |commits, index|
        result[:additions] << commits.map(&:total_additions).sum
        result[:deletions] << commits.map(&:total_deletions).sum
      end
      dataset = {
        addition: result[:additions],
        deletion: result[:deletions]
      }
      Chart.new(labels, dataset)
    end

    def total_weeks
      @commits_filter.weeks.length
    end

    def type
      'productivity'
    end

    private

    def commits_by_week
      commits = @commits_filter.group_by_week.reject do |_, v|
        v.empty?
      end
      commits_size = commits.length / 7

      return resize_commits(commits_size) if commits_size / 7 > 1

      commits
    end

    def date_format(date)
      Time.parse(date).strftime('%m/%d %H:%M')
    end

    def resize_commits(number)
      @commits_filter.group_by_week(number).reject do |_, v|
        v.empty?
      end
    end
  end
end
