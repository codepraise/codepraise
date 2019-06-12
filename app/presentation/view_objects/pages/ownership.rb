# frozen_string_literal: true

require_relative 'page'

module Views
  class Ownership < Page
    def a_board
      title = 'Collective Ownership'
      elements = [collective_chart] + collective_ownership
      Element::Board.new(title, elements)
    end

    def b_board
      title = 'Code Ownership'
      elements = [project_ownership_chart]
      Element::Board.new(title, elements)
    end

    def c_board
      title = "Ownership Distribution"
      # elements = [ownership_distribution]
      elements = [ownership_breakdown]
      Element::Board.new(title, elements)
    end

    def charts_update(params)
      path = params['path'] || ''
      [project_ownership_chart(path), ownership_breakdown(path)]
    end

    def collective_chart
      labels = ['Collective Score', 'Owned Folders', 'Owned Files']
      dataset = contributor_ids.each_with_object({}) do |email_id, result|
        result[email_id] = [
          Math.percentage(ownership_credit[email_id], ownership_credit.values.sum),
          Math.percentage( folder_filter.folders(email_id).count, all_folders_count),
          Math.percentage(folder_filter.files(email_id).count, all_files_count)
        ]
      end
      options = { title: 'Onwership Overview', scales: true, legend: true, stacked: true,
                  color: 'contributors', x_type: 'linear', y_type: 'category' }
      Element::Chart.new(labels, dataset, options, 'horizontalBar', "collective_ownership")
    end

    def all_folders_count
      contributor_ids.reduce(0) do |pre, email_id|
        pre + folder_filter.folders(email_id).count
      end
    end

    def all_files_count
      contributor_ids.reduce(0) do |pre, email_id|
        pre + folder_filter.files(email_id).count
      end
    end

    def collective_ownership
      # contributors.map do |c|
      #   lines = [[]]
      #   lines.push(name: 'Collective Score', number: ownership_credit[c.email_id],
      #              max: ownership_credit.values.sum)
      #   lines.push(name: 'Owned Folders', number: folder_filter.folders(c.email_id).count,
      #              max: folder_filter.folders.count)
      #   lines.push(name: 'Owned Files', number: folder_filter.files(c.email_id).count,
      #              max: folder_filter.files.count)
      #   Element::Bar.new(c.email_id, lines)
      # end
      contributor_ids.map do |email_id|
        dataset = [{ name: 'CollectiveScore', number: ownership_credit[email_id] },
                   { name: 'OwnedFolders', number: folder_filter.folders(email_id).count },
                   { name: 'OwnedFiles', number: folder_filter.files(email_id).count }]
        Element::SmallTable.new(email_id, dataset)
      end
    end

    def project_ownership_chart(foldername=nil)
      if foldername&.include?('basefiles')
        foldername = foldername.sub(/\/basefiles/, '')
        selected_folder = folder_filter.find_folder(foldername, folder)
        return files_chart(selected_folder)
      end

      selected_folder ||= folder_filter.find_folder(foldername, folder)

      return nil unless selected_folder

      if selected_folder.any_subfolders?
        folders_chart(selected_folder)
      else
        files_chart(selected_folder)
      end
    end

    def folders_chart(folder)
      labels = folder.subfolders.map(&:path)
      labels << "#{folder.path}/basefiles" if folder.any_base_files?
      dataset = {}
      contributors.map(&:email_id).each do |email_id|
        dataset[email_id] = folder_ownership(folder.subfolders, email_id)
        dataset[email_id] << basefile_ownership(folder.base_files, email_id) if folder.any_base_files?
      end
      options =  { title: 'Code Ownership in different folders', stacked: true, scales: true,
                   color: 'contributors', legend: true }
      Element::Chart.new(labels, dataset, options, 'bar', 'project_ownership')
    end

    def files_chart(folder)
      labels = folder.base_files.map { |file| file.file_path.filename }
      dataset = {}
      contributors.map(&:email_id).each do |email_id|
        dataset[email_id] = folder_ownership(folder.base_files, email_id)
      end
      options =  { title: 'Code Ownership in different folders', stacked: true, scales: true,
                   color: 'contributors', legend: true }
      Element::Chart.new(labels, dataset, options, 'bar', 'project_ownership')
    end

    def ownership_breakdown(path = nil)
      selected_folder = find_folder(path)
      thead = %w[Folder] + contributors.map(&:email_id)
      tbody = []
      if selected_folder.any_subfolders? && !path&.include?('basefiles')
        selected_folder.subfolders.each do |subfolder|
          tbody << [subfolder.path] + contributors.map {|c| contributor_breakdown(c.email_id, subfolder)}
        end
      else
        selected_folder.base_files.each do |subfolder|
          tbody << [filename(subfolder)] + contributors.map {|c| contributor_breakdown(c.email_id, subfolder)}
        end
      end
      Element::Table.new(thead, tbody, 'ownership_breadown')
    end

    def find_folder(path)
      if path&.include?('basefiles')
        foldername = path.sub(/\/basefiles/, '')
        folder_filter.find_folder(foldername, folder)
      else
        folder_filter.find_folder(path, folder)
      end
    end

    def contributor_breakdown(email_id, folder)
      method_touched = folder.credit_share.productivity_credit['method_credits'][email_id].to_i
      line_count = folder.credit_share.productivity_credit['line_credits'][email_id].to_i
      "MethoudToched: #{method_touched}<br>LineCount: #{line_count}"
    end

    def method_touched(folder)
      folder.credit_share.productivity_credit['method_credits'].map do |k, v|
        "#{k}: #{v.round}"
      end.join('<br>')
    end

    def line_count(folder)
      folder.credit_share.productivity_credit['line_credits'].map do |k, v|
        "#{k}: #{v.round}"
      end.join('<br>')
    end

    def page
      'ownership'
    end

    def folder_ownership(subfolders, email_id)
      subfolders.map do |folder|
        folder.line_percentage[email_id].to_i
      end
    end

    def basefile_ownership(files, email_id)
      line_credits = files.each_with_object(Hash.new(0)) do |file, result|
        file.credit_share.productivity_credit['line_credits'].each do |k, v|
          result[k] += v
        end
      end
      total_lines = line_credits.values.sum
      (line_credits[email_id].to_f / total_lines * 100).round
    end
  end
end
