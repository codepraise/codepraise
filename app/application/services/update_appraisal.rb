# frozen_string_literal: true

module CodePraise
  module Service
    class UpdateAppraisal
      include Dry::Transaction
      step :validate_project
      step :reify_appraisal

      MESSAGE = {
        404 => 'Project not found, please your project name and owner name.',
        202 => 'Project is updating, please refresh page after few minutes.'
      }.freeze

      def validate_project(input)
        input[:response] = Gateway::Api.new(CodePraise::App.config)
          .update_appraisal(input[:owner_name], input[:project_name])

        input[:response].success? ? Success(input) : Failure(input[:response].message)
      rescue StandardError
        Failure('Cannot update projects right now; please try again later')
      end

      def reify_appraisal(input)
        unless input[:response].processing?
          Representer::Appraisal.new(OpenStruct.new)
                                .from_json(input[:response].payload)
                                .yield_self { |report| input[:appraised] = report }
        end
        Success(input)
      rescue StandardError
        Failure('Error in our appraisal report -- please try again')
      end
    end
  end
end
