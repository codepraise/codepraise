# frozen_string_literal: true

module CodePraise
  # appraisal routing
  class App < Roda
    plugin :multi_route

    route('appraisal') do |routing|
      routing.on String, String do |owner_name, project_name|
        routing.get do
          @path = 'appraisal'

          path_request = ProjectRequestPath.new(
            owner_name, project_name, request
          )
          session[:watching] ||= []
          session[:watching].insert(0, path_request.project_fullname).uniq!

          result = Service::AppraiseProject.new.call(
            watched_list: session[:watching],
            requested: path_request
          )

          if result.failure? && (result.failure == 'Project not found')
            url_request = Forms::UrlRequest.new.call({ "remote_url" => "https://github.com/#{owner_name}/#{project_name}" })
            project_made = Service::AddProject.new.call(url_request)

            add_result = project_made.value!
            project = add_result.message
            session[:watching].insert(0, project.fullname).uniq!

            result = Service::AppraiseProject.new.call(
              watched_list: session[:watching],
              requested: path_request
            )
          end

          appraisal = OpenStruct.new(result.value!)

          @processing = Views::AppraisalProcessing.new(
            App.config, appraisal.response
          )

          @panel_view = PageHelper.new(appraisal, request)
            .create_page

          if request.params['type']
            Value::Elements.new(request, @panel_view).to_json
          else
            view 'dashboard', locals: { path: @path, processing: @processing,
                                        panel_view: @panel_view }
          end
        end

        routing.put do
          result = Service::UpdateAppraisal.call(owner_name, project_name)
          result.to_json
        end
      end
    end
  end
end
