# frozen_string_literal: true

require_relative '../values/init'
require_relative '../decorators/init'
require_relative '../elements/init'

module Views
  class Page
    include Element

    attr_reader :updated_at

    def initialize(appraisal, updated_at)
      @appraisal = appraisal
      @updated_at = updated_at
      @project = Views::Project.new(appraisal.project)
    end

    %i[productivity_credit quality_credit ownership_credit].each do |credit_type|
      define_method credit_type do
        folder.credit_share.send(credit_type)
      end
    end

    def method_credits(email_id = nil)
      return productivity_credit['method_credits'] unless email_id

      productivity_credit['method_credits'][email_id].to_i.round
    end

    def line_credits(email_id = nil)
      return productivity_credit['line_credits'] unless email_id

      productivity_credit['line_credits'][email_id].to_i.round
    end

    def project_url
      @project.url
    end

    def project_name
      @project.name
    end

    def project_owner
      @project.owner_name
    end

    def folder
      @appraisal.folder
    end

    def commits
      @appraisal.commits
    end

    def contributors
      folder.credit_share.contributors.sort_by(&:email_id)
    end

    def folder_filter(target_folder = nil)
      target_folder ||= folder

      Decorator::FolderFilter.new(target_folder, contributors)
    end

    def commits_filter(target_commits = nil)
      target_commits ||= commits

      Decorator::CommitsFilter.new(target_commits)
    end

    def threshold(type)
      case type
      when 'ownership'
        100 / contributors.count
      when 'complexity'
        18
      when 'test_coverage'
        70
      end
    end

    def test_coverage?
      folder.test_coverage.is_a?(Float)
    end

    def project_coverage
      return folder.test_coverage unless test_coverage?

      (folder.test_coverage * 100).round
    end

    def days_count
      commits_filter.all_dates.count
    end

    def first_date
      commits_filter.all_dates.first.strftime('%Y/%m/%d')
    end

    def last_date
      commits_filter.all_dates.last.strftime('%Y/%m/%d')
    end

    def filename(file)
      path = file.file_path
      "#{path.directory}/#{path.filename}"
    end

    def contributor_ids
      contributors.map(&:email_id)
    end

    def ruby_files(email_id = nil)
      file_selector.ruby_files.owned(email_id, threshold('ownership'))
        .unwrap
    end

    def file_selector(files = nil)
      files ||= folder_filter.files
      Decorator::FileSelector.new(files).selector
    end

    def ruby_file?(file)
      File.extname(file.file_path.filename) == '.rb'
    end

    def total_ruby_code(email_id = nil)
      ruby_files.reduce(0) do |pre, file|
        if email_id
          pre + file.credit_share.productivity_credit['line_credits'][email_id].to_i
        else
          pre + file.total_line_credits
        end
      end
    end

    def size(type)
      case type
      when 'line'
        line_credits.values.sum
      when 'method'
        folder_filter.methods.count
      when 'file'
        folder_filter.files.count
      when 'folder'
        folder_filter.folders.count
      when 'commit'
        commits.count
      when 'offense'
        folder_filter.total_offenses.count
      end
    end

    def max_addition(unit, between)
      commits_filter.by(unit, between).map(&:total_addition_credits).max
    end

    def max_deletion(unit, between)
      commits_filter.by(unit, between).map(&:total_deletion_credits).max
    end

    def code_churn_hash(commits)
      {
        addition: commits.map(&:total_addition_credits),
        deletion: commits.map { |c| c.total_deletion_credits * -1 }
      }
    end

    def complexity(file)
      file.complexity&.average.to_i
    end

    def file_path(file)
      "#{file.file_path.directory}#{file.file_path.filename}"
    end

    def method_touched
      @method_touched ||= contributor_ids.each_with_object({}) do |email_id, result|
        result[email_id] =
          productivity_credit['method_credits'][email_id].to_i
      end
    end

    def line_count
      productivity_credit['line_credits']
    end

    def commits_count
      @commits_count ||=
        contributor_ids.each_with_object({}) do |email_id, result|
          result[email_id] = commits_filter.by_email_id(email_id).count
        end
    end
  end
end
