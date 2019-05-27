# frozen_string_literal: true

require 'chainable_methods'

module CodePraise
  module Decorator
    class FileSelector < SimpleDelegator
      module Selector
        include ChainableMethods

        def email_id(files, email_id)
          return files unless email_id

          files.select do |file|
            file.line_percentage.key?(email_id)
          end
        end

        def owned(files, email_id, threshold)
          return files unless email_id

          files.select do |file|
            file.line_percentage[email_id].to_i > threshold
          end
        end

        def documentation(files, with)
          files.select do |file|
            file.has_documentation == with
          end
        end

        def offenses(files, number)
          files.select do |file|
            file.idiomaticity &&
              file.idiomaticity.offense_count >= number
          end
        end

        def too_complexity(files, threshold)
          files.select do |file|
            file.complexity&.average.to_i > threshold
          end
        end

        def test_coverage?(files)
          return [] unless check_test_coverage(files)

          files.select(&:test_coverage)
        end

        def low_test_coverage(files, threshold)
          return [] unless check_test_coverage(files)

          test_coverage?(files).select do |file|
            file.test_coverage.coverage < threshold && ruby_file?(file)
          end
        end

        def with_complexity_method(files)
          files.select do |file|
            complexity_methods = file.to_h[:methods].select do |method|
              method.complexity > 18
            end
            complexity_methods.count >= 1
          end
        end

        def ruby_files(files)
          files.select do |file|
            ruby_file?(file)
          end
        end

        def check_test_coverage(files)
          return false if files.empty?

          files.each do |file|
            return false if file.test_coverage && !file.test_coverage.message.nil?
          end
          true
        end

        def ruby_file?(file)
          File.extname(file.file_path.filename) == '.rb'
        end
      end

      attr_reader :selector

      def initialize(files)
        @selector = Selector.chain_from(files)
      end
    end
  end
end
