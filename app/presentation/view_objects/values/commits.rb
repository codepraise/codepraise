# frozen_string_literal: true

module Views
  module Value
    # Wrap multiple commits together
    class Commits
      attr_reader :commits

      def initialize(commits, date)
        @commits = commits
        @date = date
      end

      def date
        Time.parse(@date.to_s).strftime('%Y-%m-%d')
      end

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
    end
  end
end
