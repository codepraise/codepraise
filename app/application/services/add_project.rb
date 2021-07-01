# frozen_string_literal: true

require 'dry/transaction'

module CodePraise
  module Service
    # Transaction to store project from Github API to database
    class AddProject
      include Dry::Transaction

      step :validate_input
      step :request_project
      step :depresent_project

      private

      def validate_input(input)
        if input.success?
          owner_name, project_name = input[:remote_url].split('/')[-2..-1]
          Success(owner_name: owner_name, project_name: project_name)
        else
          error_message = input.errors.values.join('; ')
          Failure(Value::Result.new(:bad_request, error_message))
        end
      end

      def request_project(input)
        result = Gateway::Api.new(CodePraise::App.config)
          .add_project(input[:owner_name], input[:project_name])

        result.success? ? Success(result.payload) : Failure(result)
      rescue StandardError => e
        puts e.inspect + '\n' + e.backtrace
        Failure(Value::Result.new(:internal_error, 'Cannot add projects right now; please try again later'))
      end

      def depresent_project(project_json)
        Representer::Project.new(OpenStruct.new)
          .from_json(project_json)
          .yield_self { |project| Success(Value::Result.new(:ok, project)) }
      rescue StandardError
        Failure(Value::Result.new(:internal_error, 'Error in the project -- please try again'))
      end
    end
  end
end
