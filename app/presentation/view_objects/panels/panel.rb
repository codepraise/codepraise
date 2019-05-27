# frozen_string_literal: true

require_relative 'elements'

module Views
  class Panel
    attr_reader :project, :folder, :commits, :contributors,
                :quality_credit, :productivity_credit, :ownership_credit
    include Elements

    def initialize(appraisal)
      @project = appraisal.project
      @folder = appraisal.folder
      @commits = appraisal.commits
      @contributors = appraisal.folder.credit_share.contributors
      @quality_credit = appraisal.folder.credit_share.quality_credit
      @productivity_credit = appraisal.folder.credit_share.productivity_credit
      @ownership_credit = appraisal.folder.credit_share.ownership_credit
    end

    def category_element
      []
    end

    def panel_name
      'Individual Contribution'
    end

    def project_name
      project.name
    end

    def owner_name
      project.owner.username
    end

    def folder_tree
      build_folder_tree(@folder.subfolders) + file_element(folder.base_files)
    end

    def base_url
      "/appraisal/#{owner_name}/#{project_name}?category="
    end

    def avg_complexity(email_id)
      complexities = folder_filter.all_methods(email_id).map do |method|
        method&.complexity.to_f
      end.select(&:positive?)

      return '_' if complexities.empty?

      (complexities.sum / complexities.count).round
    end

    def has_test_coverage
      !folder.test_coverage.is_a?(String)
    end

    private

    def file_full_name(file)
      "#{file.file_path.directory}#{file.file_path.filename}"
    end

    def date_format(date)
      date = Time.parse(date) if date.is_a?(String)
      date.strftime('%y/%m/%d')
    end

    def build_folder_tree(folders)
      unless folders.empty?
        folders.map do |folder|
          subfolders_html = ''
          files_html = ''
          subfolders_html = build_folder_tree(folder.subfolders) if folder.any_subfolders?
          files_html = file_element(folder.base_files) if folder.any_base_files?
          "<li class='folder'>  #{folder_element(folder)}  <ul class='children'> #{subfolders_html} #{files_html}  </ul> </li>"
        end.join('')
      end
    end

    def folder_element(folder)
      "<span class='caret'></span>" \
      "<a href='/appraisal/#{owner_name}/#{project_name}?category=files&folder=#{folder.path}'> #{folder_name(folder)}  </a>"
    end

    def folder_name(folder)
      folder.path.split('/').last
    end

    def file_element(files)
      files = files.map do |file|
        file.file_path.filename
      end
      files.sort_by(&:length).reverse.map do |filename|
        "<li class='file'> <a href='/appraisal/#{owner_name}/#{project_name}?category=files&folder=#{filename}'>
        #{filename} </a> </li>"
      end.join('')
    end
  end
end
