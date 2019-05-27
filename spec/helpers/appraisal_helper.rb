require_relative 'spec_helper.rb'

class AppraisalHelper
  Request = Struct.new(:owner_name, :project_name, :folder_name)

  attr_reader :appraisal

  def self.build_appraisal
    request  = Request.new('iss-pay', 'IssPay', '')
    gateway = CodePraise::Gateway::Api.new(CodePraise::App.config)
    result = gateway.appraise(request)
    appraisal = CodePraise::Representer::Appraisal
      .new(OpenStruct.new).from_json(result.payload)
    appraisal = CodePraise::Representer::ProjectFolderContributions
      .new(OpenStruct.new).from_json(appraisal.content.to_json)
    new(appraisal)
  end

  def initialize(appraisal)
    @appraisal = appraisal
  end
end
