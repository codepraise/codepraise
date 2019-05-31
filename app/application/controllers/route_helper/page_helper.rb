module CodePraise
  module RouteHelper
    class PageHelper
      def initialize(appraisal, request)
        @appraisal = appraisal.appraised
        @request = request
      end

      def page
        @request.params['category'] || 'overview'
      end

      def root
        @request.params['folder']
      end

      def create_page
        Views::PageFactory.create_page(@appraisal, page, root)
      end
    end
  end
end
