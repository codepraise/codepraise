# frozen_string_literal: true

module Views
  # View for a single project entity
  class Project
    def initialize(project, index = nil)
      @project = project
      @index = index
    end

    def url
      "/appraisal/#{fullname}"
    end

    def owner_name
      @project.owner.username
    end

    def fullname
      "#{owner_name}/#{name}"
    end

    def name
      @project.name
    end

    def praise_link
      "/project/#{fullname}"
    end

  end
end
