# frozen_string_literal: true

require_relative 'file_selector'

module CodePraise
  module Decorator
    class FolderFilter < SimpleDelegator
      attr_reader :threshold

      def initialize(folder, contributors)
        super(folder)
        @contributors = contributors
        @threshold = 100 / contributors.count
      end

      def folders(email_id = nil, root_folder = nil)
        root_folder ||= self

        folders = folders_traversal(root_folder)

        folders.reject { |f| f.path == '' }
      end

      def owned_folders(percentage, email_id, root_folder = nil)
        folders(nil, root_folder).select do |folder|
          folder.line_percentage[email_id].to_i >= percentage
        end
      end

      # Select files with some conditions
      def files(email_id = nil, root_folder = nil)
        root_folder ||= self

        files = files_traversal(root_folder)

        email_id ? select_by_email_id(files, email_id) : files
      end

      def file_selector(root_folder = nil)
        FileSelector.new(files(nil, root_folder)).selector
      end

      def files_with_offenses(email_id = nil, root_folder = nil)
        files = file_selector(root_folder).offenses(1).unwrap

        return files unless email_id

        files.select do |file|
          has(file, email_id, 'offenese')
        end
      end

      def files_without_documentation(email_id = nil, root_folder = nil)
        file_selector(root_folder).owned(email_id, threshold).documentation(false)
          .unwrap
      end

      def files_with_low_coverage(email_id = nil, root_folder = nil)
        file_selector(root_folder).owned(email_id, threshold).low_test_coverage(0.7)
          .unwrap
      end

      def files_with_complexity_method(email_id = nil, root_folder = nil)
        files = file_selector(root_folder).email_id(email_id).with_complexity_method
          .unwrap

        return files unless email_id

        files.select do |file|
          has(file, email_id, 'complexity')
        end
      end

      def has(file, email_id, type)
        if type == 'offenese'
          file.idiomaticity.offenses.each do |o|
            return true if o.contributors.keys.include?(email_id)
          end
        elsif type == 'complexity'
          file.to_h[:methods].each do |method|
            if method.complexity > 18 &&
               method.line_percentage[email_id] > threshold
              return true
            end
          end
        end
        false
      end

      def owned_files(percentage, email_id, root_folder = nil)
        file_selector(root_folder).owned(email_id, percentage).unwrap
      end

      def tech_debt(email_id = nil, root_folder = nil)
        [complexity_methods(email_id), total_offenses(email_id, root_folder),
         files_without_documentation(email_id, root_folder),
         files_with_low_coverage(email_id, root_folder)]
      end

      # Select Children Entity of File Entity
      def test_cases(email_id = nil, root_folder = nil)
        file_selector(root_folder).email_id(email_id)
          .map(&:test_cases).reject(&:empty?).flatten.unwrap
      end

      def all_methods(email_id = nil, folder = nil)
        all_methods = file_selector(folder).email_id(email_id)
          .map do |file|
            file.to_h[:methods]
          end.flatten.unwrap

        email_id ? select_by_email_id(all_methods, email_id) : all_methods
      end

      def complexity_methods(email_id = nil)
        all_methods.select do |method|
          method.complexity > 18 &&
            (email_id ? method.line_percentage[email_id].to_i > threshold : true)
        end
      end

      def total_offenses(email_id = nil, folder = nil)
        offenses = file_selector(folder).map do |file|
            file.idiomaticity&.offenses
          end.flatten.reject(&:nil?).unwrap

        return offenses unless email_id

        offenses.select do |o|
          o.contributors.keys.include?(email_id)
        end
      end

      def test_coverage(folder = nil)
        folder ||= self

        if has_test_coverage(folder)
          '-'
        else
          (folder.test_coverage * 100).round
        end
      end

      def has_test_coverage(folder = nil)
        folder ||= self

        !folder.test_cases.is_a?(String)
      end

      def find_folder(folder = self, folder_path = nil)
        return folder unless folder_path

        return folder if folder.path == folder_path

        if folder.any_subfolders?
          folder.subfolders.map do |subfolder|
            find_folder(subfolder, folder_path)
          end.reject(&:nil?).first
        end
      end

      def find_file(file_name)
        files.each do |file|
          return file if file.file_path.filename == file_name
        end
      end

      def average_complexity_by(email_id, folder = nil)
        complexities = all_methods(email_id, folder).map do |method|
          method&.complexity.to_f
        end.select(&:positive?)

        return '-' if complexities.empty?

        Math.average(complexities)
      end

      def file_complexity(file)
        complexity = file.complexity.average
        complexity.nil? ? '-' : complexity
      end

      private

      def ruby_file(file)
        File.extname(file.file_path.filename) == '.rb'
      end

      def select_by_email_id(array, email_id)
        array.select do |entity|
          entity.line_percentage.key?(email_id)
        end
      end

      def files_traversal(folder)
        subfolder_files = []
        if folder.any_subfolders?
          subfolder_files = folder.subfolders.map do |subfolder|
            files_traversal(subfolder)
          end.flatten
        end
        folder.base_files + subfolder_files
      end

      def folders_traversal(folder)
        subfolders = []
        if folder.any_subfolders?
          subfolders = folder.subfolders.map do |subfolder|
            folders_traversal(subfolder)
          end.flatten
        end
        [folder] + subfolders
      end
    end
  end
end
