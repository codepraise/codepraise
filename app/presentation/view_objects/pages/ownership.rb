# frozen_string_literal: true

require_relative 'page'

module Views
  class Ownership < Page
    def a_board
      title = 'Collective Ownership'
      subtitle = 'Collective Score is the dispersion level of contribution.'
      elements = collective_ownership
      Element::Board.new(title, subtitle, elements)
    end

    def b_board
      title = 'Code Ownership'
      elements = [project_ownership_chart]
      Element::Board.new(title, nil, elements)
    end

    def c_board
      title = "Ownership Distribution"
      # elements = [ownership_distribution]
      elements = [ownership_breakdown]
      Element::Board.new(title, nil, elements)
    end

    def charts_update(params)
      if params.keys.include?('path')
        path = params['path'] || ''
        [project_ownership_chart(path), ownership_breakdown(path)]
      elsif params.keys.include?('email_id')
        return [ownership_distribution] if params['email_id'] == 'total'

        [individual_ownership(params['email_id'])]
      end
    end

    def collective_ownership
      contributors.map do |c|
        lines = [[]]
        lines.push(name: 'Collective Score', number: ownership_credit[c.email_id],
                   max: ownership_credit.values.sum)
        lines.push(name: 'Owned Folders', number: folder_filter.folders(c.email_id).count,
                   max: folder_filter.folders.count)
        lines.push(name: 'Owned Files', number: folder_filter.files(c.email_id).count,
                   max: folder_filter.files.count)
        Element::Bar.new(c.email_id, lines)
      end
    end

    def project_ownership_chart(foldername=nil)
      if foldername&.include?('basefiles')
        foldername = foldername.sub(/\/basefiles/, '')
        selected_folder = folder_filter.find_folder(folder, foldername)
        return files_chart(selected_folder)
      end

      selected_folder ||= folder_filter.find_folder(folder, foldername)

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
      Element::Chart.new(labels, dataset, { title: 'Code Ownership in different folders', stacked: true, scales: true, update: 'label', legend: true }, 'bar', 'project_ownership')
    end

    def files_chart(folder)
      labels = folder.base_files.map { |file| file.file_path.filename }
      dataset = {}
      contributors.map(&:email_id).each do |email_id|
        dataset[email_id] = folder_ownership(folder.base_files, email_id)
      end
      Element::Chart.new(labels, dataset, { title: 'Code Ownership in different folders', stacked: true, scales: true, update: 'label', legend: true  }, 'bar', 'project_ownership')
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
        folder_filter.find_folder(folder, foldername)
      else
        folder_filter.find_folder(folder, path)
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

    def individual_ownership(email_id = nil)
      email_id ||= contributors.first.email_id
      dataset = individual_stucture(folder, {}, email_id)
      dataset = nil if folder.line_percentage[email_id].zero?
      options = { title: "#{email_id} Code Onwership" }
      Element::Chart.new(nil, [dataset], options, 'treemap', 'treemap')
    end

    def ownership_distribution
      dataset = ownership_structure(folder, {})
      Element::Chart.new(nil, [dataset], {}, 'treemap', 'treemap')
    end

    def individual_stucture(folder, hash, email_id)
      if folder.any_subfolders?
        hash['children'] = folder.subfolders.map do |subfolder|
          individual_stucture(subfolder, {}, email_id)
        end
      else
        hash['value'] = folder.line_percentage[email_id].to_i
      end
      hash['text'] = folder.path
      hash
    end

    def ownership_structure(folder, hash)
      hash['text'] = folder.path
      if folder.any_subfolders?
        hash['children'] = folder.subfolders.map do |subfolder|
          ownership_structure(subfolder, {})
        end
        hash['children'] << base_files_children(folder) if folder.any_base_files?
      else
        hash['children'] = contributors_children(folder)
      end
      hash
    end

    def contributors_children(folder)
      contributors.map do |c|
        {
          text: c.email_id,
          value: folder.line_percentage[c.email_id].to_i
        }
      end
    end

    def base_files_children(folder)
      line_credits = folder.base_files.map do |file|
        file.credit_share.productivity_credit['line_credits']
      end
      line_credits = line_credits.reduce(Hash.new(0)) do |pre, hash|
        hash.each do |k, v|
          pre[k] += v
        end
        pre
      end

      children = contributors.map do |c|
        {
          text: c.email_id,
          value: Math.percentage(line_credits[c.email_id].to_i, line_credits.values.sum)
        }
      end
      {
        text: 'basefiles',
        children: children
      }
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
