# frozen_string_literal: true

module CodePraise
  module RouteHelper
    class JsonResponse
      HTTP_CODE = {
        ok: 200,
        created: 201,
        processing: 202,

        forbidden: 403,
        not_found: 404,
        bad_request: 400,
        conflict: 409,
        cannot_process: 422,

        internal_error: 500
      }.freeze


      def initialize(result)
        @result = result
      end

      def http_status_code
        HTTP_CODE[@result.status]
      end

      def send(response, representer)
        response.status = http_status_code

        return representer.new(@result.message).to_json if representer

        to_json
      end

      private

      def to_json
        { message: @result.message}.to_json
      end
    end
  end
end
