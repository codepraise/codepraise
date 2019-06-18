# frozen_string_literal: true

require_relative 'pages/init'

module Views
  class PageFactory
    KLASS = {
      'productivity' => Views::Productivity,
      'quality' => Views::Quality,
      'overview' => Overview,
      'ownership' => Ownership,
      'functionality' => Functionality,
      'files' => Files
    }.freeze

    def self.create_page(appraisal, page, root = nil)
      content = CodePraise::Representer::ProjectFolderContributions.new(OpenStruct.new)
        .from_json(appraisal.content.to_json)
      if page == 'files'
        KLASS[page].new(content, appraisal.updated_at, root)
      else
        KLASS[page].new(content, appraisal.updated_at)
      end
    end
  end
end
