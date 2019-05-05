# frozen_string_literal: true

module CodePraise
  module RouteHelper
    class PanelHelper
      KLASS = {
        'productivity' => Views::ProductivityPanel
      }.freeze

      def initialize(result, category = nil)
        @result = result
        @category = category || 'productivity'
      end

      def view_obj
        KLASS[@category].new(appraisal) if appraised?
      end

      def appraisal
        @result.appraised if appraised?
      end

      private

      def appraised?
        !@result.response.processing?
      end
    end
  end
end
