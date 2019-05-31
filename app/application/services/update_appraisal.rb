# frozen_string_literal: true

module CodePraise
  module Service
    class UpdateAppraisal
      MESSAGE = {
        404 => 'Project not found, please your project name and owner name.',
        202 => 'Project is updating, please refresh page after few minutes.'
      }

      def self.call(ownername, project_name)
        result = Gateway::Api.new(CodePraise::App.config)
          .update_appraisal(ownername, project_name)
        { message: MESSAGE[result.code] }
      end
    end
  end
end
