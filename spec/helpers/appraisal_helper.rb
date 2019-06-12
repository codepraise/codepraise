require_relative 'spec_helper.rb'

class AppraisalHelper
  Request = Struct.new(:owner_name, :project_name, :folder_name)

  attr_reader :appraisal

  def self.build_appraisal
    request = Request.new('XuVic', 'YPBT-app', '')
    gateway = CodePraise::Gateway::Api.new(CodePraise::App.config)
    result = gateway.appraise(request)
    CodePraise::Representer::Appraisal
      .new(OpenStruct.new).from_json(result.payload)
  end
end
