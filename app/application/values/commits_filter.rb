# frozen_string_literal: true

module CodePraise
  module Value
    class CommitsFilter
      HOUR = 60 * 60
      DAY = 24 * HOUR
      WEEK = 7 * DAY
      MONTH = 30 * DAY

      Commits = Struct.new(:commits, :date) do
        def total_addition_credits
          @total_addition_credits ||= commits.reduce(0) do |pre, commit|
            pre + commit.total_addition_credits
          end
        end

        def total_deletion_credits
          @total_deletion_credits ||= commits.reduce(0) do |pre, commit|
            pre + commit.total_deletion_credits
          end
        end

        def select(email_id)
          commits.select do |commit|
            commit.committer.email_id == email_id
          end
        end
      end

      def initialize(commits)
        @commits = commits.sort_by {|commit| Time.parse(commit.date)}
      end

      def select_by_week(start_week, end_week)
        raise RangeError, 'Over the range of week' if end_week > total_weeks || start_week < 1

        group_by_week.values[start_week - 1..end_week - 1].flatten
      end

      def select_by_contributor(email_id)
        @commits.select do |commit|
          commit.committer.email_id == email_id
        end
      end

      def merge_by_day
        merged_commits = @commits.group_by do |commit|
          start_date = date(commit.date)[0]
          start_date
        end
        merged_commits.map do |k, v|
          Commits.new(v, k)
        end
      end

      def commits_between(start_date, end_date, commits)
        start_date = Time.parse(start_date) if start_date.is_a?(String)
        end_date = Time.parse(end_date) if end_date.is_a?(String)
        commits.select do |commit|
          commit_time = commit.date.is_a?(String) ? Time.parse(commit.date) : commit.date
          start_date <= commit_time && commit_time <= end_date
        end
      end

      def group_by_week(number = 1)
        since = first_date
        to = since + WEEK * number
        weeks_num = (total_weeks.to_f / number).ceil
        weeks_num.times.each_with_object({}) do |week, result|
          result[week_name(week, number)] = commits_between(since, to, merge_by_day)
          since = to
          to = since + WEEK * number
        end
      end

      def week_name(week, number)
        last_week = (week + 1) * number
        if number == 1
          "#{week + 1} week"
        else
          last_week = weeks.last if last_week > weeks.last
          "#{last_week - number + 1} ~ #{last_week} weeks"
        end
      end

      def weeks
        ((last_date - first_date) / WEEK).ceil.times.map {|w| w + 1}
      end

      def total_weeks
        weeks.length
      end

      def months
        ((last_date - first_date) / MONTH).ceil
      end

      def first_date
        Time.parse(@commits.first.date)
      end

      def last_date
        Time.parse(@commits.last.date)
      end

      def date(time)
        if time =~ /(\d+-\d+-\d+)/
          start_date = Time.parse($1)
          end_date = start_date + DAY
          [start_date, end_date]
        end
      end
    end
  end
end
