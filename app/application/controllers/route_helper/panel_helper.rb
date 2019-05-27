# frozen_string_literal: true

module CodePraise
  module RouteHelper
    class PanelHelper
      KLASS = {
        'productivity' => Views::Productivity,
        'quality' => Views::Quality,
        'ownership' => Views::Ownership,
        'functionality' => Views::Functionality,
        'overview' => Views::Overview,
        'files' => Views::Files
      }.freeze

      def initialize(result, request)
        @result = result
        @request = request
        @category = request.params['category'] || 'overview'
      end

      def view_obj
        if @category == 'files'
          folder = @request['folder']
          KLASS[@category].new(appraisal, folder) if appraised?
        elsif appraised?
          KLASS[@category].new(appraisal)
        end
      end

      def appraisal
        retrun nil unless appraised?

        Representer::ProjectFolderContributions.new(OpenStruct.new)
          .from_json(@result.appraised.content.to_json)
      end

      private

      def appraised?
        !@result.response.processing?
      end
    end
  end
end
