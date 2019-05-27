# frozen_string_literal: true

module CodePraise
  module Decorator
    class CommitsFilter
      HOUR = 60 * 60
      DAY = 24 * HOUR
      WEEK = 7 * DAY
      MONTH = 30 * DAY
      attr_reader :commits

      Commits = Struct.new(:commits, :date) do
        def total_addition_credits
          return 0 if commits.nil? || commits.empty?

          @total_addition_credits ||= commits.reduce(0) do |pre, commit|
            pre + commit.total_addition_credits
          end
        end

        def total_deletion_credits
          return 0 if commits.nil? || commits.empty?

          @total_deletion_credits ||= commits.reduce(0) do |pre, commit|
            pre + commit.total_deletion_credits
          end
        end

        def message
          commits.map(&:message).flatten
        end
      end

      def initialize(commits)
        @commits = commits.sort_by { |commit| Time.parse(commit.date) }
      end

      def by_path(file_path)
        selected_commits = commits.select do |commit|
          file_exist?(commit, file_path)
        end
        merge_by_day(selected_commits)
      end

      def file_exist?(commit, file_path)
        commit.file_changes.each do |file|
          return true if file.path.include?(file_path)
        end

        return false
      end

      def between(start_date, end_date)
        start_date = Time.parse(start_date) if start_date.is_a?(String)
        end_date = Time.parse(end_date) if end_date.is_a?(String)
        commits.select do |commit|
          commit_time = commit.date.is_a?(String) ? Time.parse(commit.date) : commit.date
          start_date <= commit_time && commit_time <= end_date
        end
      end

      def by(unit, between = nil, email_id = nil)
        selected_commits ||= commits
        selected_commits = by_email_id(email_id) if email_id

        case unit
        when 'day'
          by_day(selected_commits, between)
        when 'week'
          by_week(selected_commits, between)
        when 'month'
          by_month(selected_commits, between)
        end
      end

      def by_day(selected_commits, between)
        by_day = selected_commits.group_by do |commit|
          date(commit.date)
        end

        all_days(between).map do |d|
          date = date(d)
          Commits.new(by_day[date], d)
        end
      end

      def by_week(selected_commits, between)
        by_day = by_day(selected_commits, between)
        th = 1
        by_week = by_day.each_with_object({}) do |commit, result|
          result[th] ||= []
          result[th] << commit if result[th].empty? || result[th].last.date.wday < commit.date.wday
          th += 1 if commit.date.wday == 6
        end
        by_week.map do |_, v|
          Commits.new(v, v[0].date)
        end
      end

      def by_month(selected_commits, between)
        by_month = by_day(selected_commits, between).group_by do |commit|
          month(commit.date)
        end

        by_month.map do |k, v|
          Commits.new(v, Time.parse("#{k}-01"))
        end
      end

      def by_email_id(email_id)
        commits.select do |commit|
          commit.committer.email_id == email_id
        end
      end

      def select_by_contributor(email_id)
        @commits.select do |commit|
          commit.committer.email_id == email_id
        end
      end

      def merge_by_day(selected_commits)
        by_day = selected_commits.group_by do |commit|
          date(commit.date)
        end

        by_day.map do |k, v|
          Commits.new(v, k)
        end
      end

      def first_date
        Time.parse(date(@commits.first.date))
      end

      def all_days(between = nil)
        days = (last_date - first_date) / DAY
        dates = []
        (days + 1).to_i.times do |day|
          dates << first_date + day * DAY
        end

        return dates unless between

        dates.select do |date|
          date >= Time.parse(between[0]) && date <= Time.parse(between[1])
        end
      end

      def last_date
        Time.parse(date(@commits.last.date)) + DAY
      end

      def date(time)
        Time.parse(time.to_s).strftime('%Y-%m-%d')
      end

      def month(time)
        Time.parse(time.to_s).strftime('%Y-%m')
      end
    end
  end
end
