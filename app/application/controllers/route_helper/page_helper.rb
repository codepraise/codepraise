module CodePraise
  module RouteHelper
    class PageHelper
      def initialize(appraisal, request)
        @appraisal = appraisal
        @request = request
      end

      def page
        @request.params['category'] || 'overview'
      end

      def root
        @request.params['folder']
      end

      def appraised?
        !@appraisal.response.processing?
      end

      def create_page
        return nil unless appraised?

        Views::PageFactory.create_page(@appraisal.appraised, page, root)
      end
    end
  end
end
