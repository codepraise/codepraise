# frozen_string_literal: true

require_relative 'file_selector'

module Views
  module Decorator
    # Filter Folders or Files with some condition
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
          .reject { |f| f.path == '' }

        return folders unless email_id

        folders.select do |folder|
          folder.line_percentage[email_id].to_i >= threshold
        end
      end

      def owned_folders(email_id, percentage, root_folder = nil)
        folders(nil, root_folder).select do |folder|
          folder.line_percentage[email_id].to_i >= percentage && !empty_folder?(folder)
        end
      end

      def empty_folder?(folder)
        folder.any_subfolders? && !folder.any_base_files?
      end

      # Get All files
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

      def quality_problems(email_id = nil, root_folder = nil)
        [complexity_methods(email_id), total_offenses(email_id, root_folder).count,
         unannotated_class(email_id), low_test_coverage(email_id)]
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

      def unannotated_class(email_id)
        return files_without_documentation.count unless email_id

        files_without_documentation.map do |file|
          1.0 * (file.line_percentage[email_id].to_f / 100)
        end.sum.round
      end

      def low_test_coverage(email_id)
        return files_with_low_coverage.count unless email_id

        files_with_low_coverage.map do |file|
          1.0 * (file.line_percentage[email_id].to_f / 100)
        end.sum.round
      end

      # def owned_methods(email_id, folder = nil)
      #   all_methods(nil, folder).select do |method|
      #     method.line_percentage[email_id].to_i >= threshold
      #   end
      # end

      def complexity_methods(email_id = nil)
        file_selector.to_methods.too_complexity(15).unwrap.map do |method|
          if email_id
            1.0 * (method.line_percentage[email_id].to_f / 100)
          else
            1
          end
        end.sum.round
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

      def find_folder(folder_path = nil, folder = self)
        return folder unless folder_path

        return folder if folder.path == folder_path

        if folder.any_subfolders?
          folder.subfolders.map do |subfolder|
            find_folder(folder_path, subfolder)
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
          max = entity.line_percentage.values.max
          entity.line_percentage[email_id] == max
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
