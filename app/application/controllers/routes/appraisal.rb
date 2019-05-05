# frozen_string_literal: true

module CodePraise
  class App < Roda
    plugin :multi_route

    route('appraisal') do |routing|
      routing.on String, String do |owner_name, project_name|
        routing.get do
          @path = 'appraisal'

          path_request = ProjectRequestPath.new(
            owner_name, project_name, request
          )

          result = Service::AppraiseProject.new.call(
            watched_list: session[:watching],
            requested: path_request
          )

          appraisal = OpenStruct.new(result.value!)
          @processing = Views::AppraisalProcessing.new(
            App.config, appraisal.response
          )
          view 'dashboard', locals: { path: @path, processing: @processing }
        end
      end
    end
  end
end
