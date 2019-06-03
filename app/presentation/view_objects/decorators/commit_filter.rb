# frozen_string_literal: true

require_relative '../values/init'

module Views
  module Decorator
    # Filter Commits with Time Range or Time Unit
    class CommitsFilter
      HOUR = 60 * 60
      DAY = 24 * HOUR
      WEEK = 7 * DAY
      MONTH = 30 * DAY
      attr_reader :commits

      def initialize(commits)
        @commits = commits.sort_by { |commit| Time.parse(commit.date) }
      end

      def by_path(file_path)
        selected_commits = commits.select do |commit|
          file_exist?(commit, file_path)
        end
        between = [selected_commits.first.date, selected_commits.last.date]
        by_day(selected_commits, between)
      end

      def file_exist?(commit, file_path)
        commit.file_changes.each do |file|
          return true if file.path.include?(file_path)
        end

        false
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

        all_dates(between).map do |d|
          date = date(d)
          Value::Commits.new(by_day[date], d)
        end
      end

      def by_week(selected_commits, between)
        by_day = by_day(selected_commits, between)
        th = 0
        by_week = by_day.each_with_object({}) do |commit, result|
          th += 1 if Time.parse(commit.date.to_s).wday == 6
          result[th] ||= []
          result[th] << commit
        end
        by_week.map do |_, dates|
          Value::Commits.new(dates, dates[0].date)
        end
      end

      def by_month(selected_commits, between)
        by_month = by_day(selected_commits, between).group_by do |commit|
          month(commit.date)
        end

        by_month.map do |k, v|
          Value::Commits.new(v, Time.parse("#{k}-01"))
        end
      end

      def by_email_id(email_id)
        commits.select do |commit|
          commit.committer.email_id == email_id
        end
      end

      # get all dates include the date without any commit
      def all_dates(between = nil)
        days = ((last_date - first_date) / DAY).round + 1
        dates = Array(0..days).map do |day|
          first_date - DAY + day * DAY
        end

        return dates unless between

        date_between(dates, between)
      end

      def date_between(dates, between)
        dates.select do |date|
          date >= Time.parse(between[0]) && date <= Time.parse(between[1])
        end
      end

      def first_date
        Time.parse(date(@commits.first.date))
      end

      def last_date
        Time.parse(date(@commits.last.date)) + DAY
      end

      # remove hour,min and second
      def date(time)
        Time.parse(time.to_s).strftime('%Y-%m-%d')
      end

      # remove day and time
      def month(time)
        Time.parse(time.to_s).strftime('%Y-%m')
      end
    end
  end
end
