# frozen_string_literal: true

require_relative 'panel'

module Views
  class Ownership < Panel
    attr_reader :root_folder, :folder_filter

    def initialize(appraisal)
      super(appraisal)
      @root_folder = appraisal.folder
      @folder_filter = CodePraise::Decorator::FolderFilter.new(root_folder, contributors)
    end

    def a_board
      title = 'Collective Score'
      elements = collective_ownership
      Board.new(title, nil, nil, elements)
    end

    def b_board
      title = 'Code Ownership'
      elements = [project_ownership_chart]
      Board.new(title, nil, nil, elements)
    end

    def c_board
      title = "Ownership Distribution"
      elements = [ownership_distribution]
      Board.new(title, nil, nil, elements)
    end

    def sub_charts(params)
      if params.keys.include?('path')
        path = params['path'] || ''
        [project_ownership_chart(path)]
      elsif params.keys.include?('email_id')
        return [ownership_distribution] if params['email_id'] == 'total'

        [individual_ownership(params['email_id'])]
      end
    end

    def collective_ownership
      titles = ['Collective Score', 'Owned Folders', 'Owned Files']
      lines = [collective_lines, owned_lines('folders'), owned_lines('files')]
      titles.each_with_index.map do |title, i|
        Bars.new(lines[i], title, true)
      end
    end

    def collective_lines
      total = ownership_credit.values.sum
      lines = [{ name: 'Contributor', number: 'Total' }]
      lines += contributors.map do |c|
        number = ownership_credit[c.email_id]
        line_hash(c.email_id, number, total)
      end
      lines
    end

    def owned_lines(method)
      total = folder_filter.send(method).count
      threshold = 100 / contributors.count
      lines = [{ name: 'Contributor', number: 'Total' }]
      lines += contributors.map do |c|
        number = folder_filter.send("owned_#{method}", threshold, c.email_id).count
        line_hash(c.email_id, number, total)
      end
      lines
    end

    def line_hash(name, number, max)
      {
        name: name,
        line: { width: Math.percentage(number, max), max: max },
        number: number
      }
    end

    def table
      thead = ["Contributor", "CollectiveCredit", "OwnedFiles"]
      Table.new(thead, contributors_credits.values, 'main_table')
    end

    def contributors_credits
      @contributors.each_with_object({}) do |contributor, result|
        result[contributor.email_id] = tbody(contributor.email_id)
      end
    end

    def tbody(email_id)
      ownership_credit = root_folder.credit_share.ownership_credit[email_id]
      [email_id, ownership_credit, owned_files(email_id)]
    end

    def owned_files(email_id)
      folder_filter.files.select do |file|
        file.line_percentage[email_id].to_i > 33
      end.count
    end

    def email_id?(email_id)
      contributors.map(&:email_id).include?(email_id)
    end

    def project_ownership_chart(foldername=nil)
      if foldername&.include?('basefiles')
        foldername = foldername.sub(/\/basefiles/, '')
        folder = folder_filter.find_folder(root_folder, foldername)
        return files_chart(folder)
      end

      folder ||= folder_filter.find_folder(root_folder, foldername)

      return nil unless folder

      if folder.any_subfolders?
        folders_chart(folder)
      else
        files_chart(folder)
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
      Chart.new(labels, dataset, { title: 'Code Ownership in different folders', stacked: true, scales: true, update: 'label', legend: true }, 'bar', 'project_ownership')
    end

    def files_chart(folder)
      labels = folder.base_files.map { |file| file.file_path.filename }
      dataset = {}
      contributors.map(&:email_id).each do |email_id|
        dataset[email_id] = folder_ownership(folder.base_files, email_id)
      end
      Chart.new(labels, dataset, { title: 'Code Ownership in different folders', stacked: true, scales: true, update: 'label', legend: true  }, 'bar', 'project_ownership')
    end

    def individual_ownership(email_id = nil)
      email_id ||= contributors.first.email_id
      title = "#{email_id}'s Ownership Distribution'"
      dataset = individual_stucture(root_folder, {}, email_id)
      dataset = nil if root_folder.line_percentage[email_id].zero?

      Chart.new(nil, [dataset], { title: "#{email_id}'s Code Ownership'"}, 'treemap', 'treemap')
    end

    def ownership_distribution
      title = ''
      dataset = ownership_structure(folder, {})
      Chart.new(nil, [dataset], { title: "test"}, 'treemap', 'treemap')
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

    def find_folder(foldername = nil)
      folder = root_folder

      if foldername
      end
      folder
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
