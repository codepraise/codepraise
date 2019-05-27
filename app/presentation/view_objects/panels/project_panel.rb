# frozen_string_literal: true

module Views
  class ProjectPanel < Panel
    attr_reader :target_folder, :folder_filter, :credit_share,
                :productivity_credit, :quality_credit

    def initialize(appraisal, folder_name = nil)
      super(appraisal)
      @folder_filter = CodePraise::Decorator::FolderFilter.new(appraisal.folder)
      @target_folder = @folder_filter.find_folder(appraisal.folder, folder_name)
      @credit_share = @target_folder.credit_share
      @productivity_credit = @credit_share.productivity_credit
      @quality_credit = @credit_share.quality_credit
    end

    def a_board
      title = ''
      elements = [folder_percentage_chart]
      Board.new(title, nil, nil, elements)
    end

    def b_board
      title = ''
      elements = [individaul_credit_table(nil)]
      Board.new(title, nil, nil, elements)
    end

    def c_board
      title = ''
      subtitle = ''
      elements = [file_churn_chart]
      Board.new(title, subtitle, nil, elements)
    end

    def folder_percentage_chart
      labels, dataset = sub_elements(target_folder)
      options = { title: 'Folder Composition', scales: true, legend: true }
      Chart.new(labels, dataset, options, 'bar', 'folder_composition')
    end

    def individaul_credit_table(folder_path)
      folder = folder_filter.find_folder(target_folder, folder_path)
      thead = %w[Measure Total] + contributors.map(&:email_id)
      Table.new(thead, tbody(folder), 'individual_credit')
    end

    def file_churn_chart
      dataset = folder_filter.files(nil, target_folder).map do |file|
        { x: file.commits_count, y: file.complexity&.average.to_i,
          title: file.file_path.filename }
      end
      options = { title: 'File Churn', scales: true, legend: false,
                  x_type: 'linear', tooltips: true, axes_label: true }
      Chart.new(nil, dataset, options,
                'scatter', 'folder_churn')
    end

    def type
      'project'
    end

    def sub_elements(root)
      elements = root.any_subfolders? ? root.subfolders : root.base_files
      elements.sort_by!(&:total_line_credits).reverse!
      labels = if root.any_subfolders?
                 elements.map(&:path)
               else
                 elements.map { |f| f.file_path.filename }
               end
      total = elements.map(&:total_line_credits).sum
      dataset = elements.map do |element|
        Math.percentage(element.total_line_credits.to_f, total)
      end
      [labels, dataset]
    end

    def tbody(folder)
      complexity = ['AvgComplexity', folder.average_complexity.round] +
                   contributors.map { |c| average_complexity(c.email_id, folder) }
      offenses = ['OffenseCount', folder.total_offenses] +
                 to_values(quality_credit['idiomaticity_credits']).map(&:abs)
      documentation = ['Documentation', folder.total_documentation] +
                      to_values(quality_credit['documentation_credits'])
      test_coverage = ['TestCoverage', folder_filter.test_coverage(folder)] +
                      contributors.map { |c| average_test_coverage(c.email_id, folder) }
      method_count = ['MethodCount', folder.total_method_credits] +
                     to_values(productivity_credit['method_credits'])
      line_count = ['LineCount', folder.total_line_credits] +
                   to_values(productivity_credit['line_credits'])
      [complexity, offenses, documentation, test_coverage, method_count, line_count]
    end

    def average_test_coverage(email_id, folder)
      return '-' unless folder_filter.has_test_coverage(folder)

      percentage = 100 / contributors.count
      owned_files = folder_filter.owned_files(percentage, email_id, folder)
      sum_coverage = owned_files.reduce(0) do |pre, file|
        pre + file.test_coverage&.coverage.to_f
      end
      Math.percentage(sum_coverage, owned_files.count)
    end

    def average_complexity(email_id, element)
      folder_filter.average_complexity_by(email_id, element)
    end

    def to_values(hash)
      contributors.each_with_object([]) do |contributor, result|
        result << hash[contributor.email_id].to_i
      end
    end
  end
end
