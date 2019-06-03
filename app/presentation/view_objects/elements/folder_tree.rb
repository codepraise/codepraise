# frozen_string_literal: true

module Views
  module Element
    class FolderTree
      def initialize(folder, owner_name, project_name, path)
        @folder = folder
        @owner_name = owner_name
        @project_name = project_name
        @path = path
      end

      def to_element
        "<li class='root_folder'> <a href='/appraisal/#{@owner_name}/#{@project_name}?category=files'> root </a></li>" +
          build_folder_tree(@folder.subfolders) +
          file_element(@folder.base_files)
      end

      def build_folder_tree(folders)
        return nil if folders.empty?

        folders.map do |folder|
          active = active?(folder) ? 'active' : ''
          subfolders_html = build_folder_tree(folder.subfolders) if folder.any_subfolders?
          files_html = file_element(folder.base_files) if folder.any_base_files?
          "<li class='folder'>  #{folder_element(folder)}" \
            "<ul class='children #{active}'> #{subfolders_html} #{files_html}" \
            '</ul>' \
          '</li>'
        end.join('')
      end

      def folder_element(folder)
        down = active?(folder) ? 'caret-down' : ''
        "<span class='caret #{down}'></span>" \
        "<a href='/appraisal/#{@owner_name}/#{@project_name}?" \
        "category=files&folder=#{folder.path}'>" \
        "#{folder_name(folder)}  </a>" \
      end

      def active?(folder)
        @path.include?(folder.path)
      end

      def folder_name(folder)
        folder.path.split('/').last
      end

      def file_element(files)
        files = files.map do |file|
          file.file_path.filename
        end
        files.sort_by(&:length).reverse.map do |filename|
          "<li class='file'>" \
            "<a href='/appraisal/#{@owner_name}/#{@project_name}?" \
            "category=files&folder=#{filename}'>" \
            "#{filename} </a>" \
          '</li>'
        end.join('')
      end
    end
  end
end
