# frozen_string_literal: true

module Views
  class ProductivityPanel
    attr_reader :project, :folder, :commits

    def initialize(appraisal)
      @project = appraisal.project
      @folder = appraisal.folder
      @commits = appraisal.commits
    end

    def project_name
      project.name
    end

    def folder_tree
      build_folder_tree(@folder.subfolders)
    end

    private

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
      "<a href=''> #{folder.path}  </a>"
    end

    def file_element(files)
      files.map do |file|
        file.file_path.filename
      end.sort_by(&:length).reverse.map do |filename|
        "<li class='file'>  <a href=''> #{filename} </a> </li>"
      end.join('')
    end
  end
end
