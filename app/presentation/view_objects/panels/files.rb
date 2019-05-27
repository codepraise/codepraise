# frozen_string_literal: true

module Views
  class Files < Panel
    attr_reader :folder_filter, :root, :state, :credit_share, :commits_filter

    def initialize(appraisal, root)
      super(appraisal)
      @commits_filter = CodePraise::Decorator::CommitsFilter.new(appraisal.commits)
      @folder_filter = CodePraise::Decorator::FolderFilter.new(appraisal.folder, contributors)
      @root = root.nil? ? @folder_filter.folders[0] : @folder_filter.find_folder(folder, root)
      @state = 'folder'
      if @root.nil?
        @root = @folder_filter.find_file(root)
        @state = 'file'
      end
      @credit_share = @root.credit_share
    end

    def a_board
      elements = [size_infos, structure_infos, quality_infos, ownership_infos]
      Board.new(nil, nil, nil, elements)
    end

    def b_board
      title = ''
      elements = [break_down]
      Board.new(title, nil, nil, elements)
    end

    def c_board
      title = ''
      elements = [progress]
      Board.new(title, nil, nil, elements)
    end

    def break_down
      labels = []
      dataset = contributors.each_with_object({}) { |c, hash| hash[c.email_id] = [] }
      if folder?
        files = folder_filter.files(nil, root)
        files.each do |file|
          labels << file.file_path.filename
          dataset.each do |k, _|
            dataset[k] << file.line_percentage[k].to_i
          end
        end
      else
        labels << root.file_path.filename
        dataset.each do |k, _|
          dataset[k] << root.line_percentage[k].to_i
        end
      end
      options = { stacked: true, legend: true, title: 'code ownership' }
      Chart.new(labels, dataset, options, 'bar', 'break_down')
    end

    def progress(unit = nil, between = nil)
      commits = commits_filter.by_path(name)
      labels = commits.map(&:date)
      dataset = {
        addition: commits.map(&:total_addition_credits),
        deletion: commits.map(&:total_deletion_credits)
      }
      options = {  legend: true }
      Chart.new(labels, dataset, options, 'line', 'progress')
    end

    def size_infos
      infos = []
      infos << { name: 'Line of Code', number: root.total_line_credits }
      infos << { name: 'Number of SubFolders', number: subfolders.count }
      infos << { name: 'Number of Files', number: files.count }
      SmallTable.new('Size', infos)
    end

    def structure_infos
      infos = []
      methods_count = methods.select do |method|
        %w[def defs].include?(method.type)
      end.count
      block_count = methods.select do |method|
        method.type == 'block'
      end.count
      infos << { name: 'Number of Method', number: methods_count }
      infos << { name: 'Number of Block', number: block_count }
      SmallTable.new('Structure', infos)
    end

    def quality_infos
      infos = []
      infos << { name: 'Avg. Complexity', number: avg_complexity }
      infos << { name: 'Number of Code Style Offense', number: offense_count }
      infos << { name: 'Number of Documnetation', number: documentation_count }
      infos << { name: 'Test Coverage', number: test_coverage }
      SmallTable.new('Quality', infos)
    end

    def ownership_infos
      infos = contributors.map do |c|
        {
          name: c.email_id,
          number: root.line_percentage[c.email_id].to_i
        }
      end
      SmallTable.new('Ownership', infos)
    end

    def avg_complexity
      if folder?
        root.average_complexity.round
      else
        return '-' if root.complexity.nil?

        root.complexity.average.round
      end
    end

    def offense_count
      if folder?
        folder_filter.total_offenses(nil, root).count
      else
        return 0 if root.idiomaticity.nil?

        root.idiomaticity.offense_count
      end
    end

    def documentation_count
      credit_share.quality_credit['documentation_credits'].values.sum
    end

    def test_coverage
      return '-' unless has_test_coverage

      if folder?
        (root.test_coverage * 100).round
      else
        return '-' if root.test_coverage.nil?

        (root.test_coverage.coverage * 100).round
      end
    end

    def methods
      if folder?
        folder_filter.all_methods(nil, root)
      else
        root.to_h[:methods]
      end
    end

    def subfolders
      if folder?
        root.subfolders
      else
        []
      end
    end

    def files
      if folder?
        root.base_files
      else
        [root]
      end
    end

    def name
      if state == 'folder'
        @root.path
      else
        path = @root.file_path
        "#{path.directory}#{path.filename}"
      end
    end

    def folder?
      state == 'folder'
    end

    def page
      'files'
    end
  end
end
