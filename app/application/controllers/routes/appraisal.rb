# frozen_string_literal: true

module CodePraise
  # appraisal routing
  class App < Roda
    plugin :multi_route
    plugin :request_headers

    route('appraisal') do |routing|
      routing.on String, String do |owner_name, project_name|
        @project_path = "#{App.config.APP_HOST}/appraisal/#{owner_name}/#{project_name}"
        routing.is 'update' do
          routing.get do
            @path = 'appraisal'

            result = Service::UpdateAppraisal.new.call(
              owner_name: owner_name,
              project_name: project_name
            )

            appraisal = OpenStruct.new(result.value!)

            @processing = Views::AppraisalProcessing.new(
              App.config, appraisal.response
            )

            @panel_view = PageHelper.new(appraisal, request)
                                    .create_page

            if request.params['type']
              Value::Elements.new(request, @panel_view).to_json
            else
              view 'progress_bar', locals: { path: @path, processing: @processing,
                                             project_path: @project_path, panel_view: @panel_view }
            end
          end
        end

        routing.get do
          cache_control = Cache::Control.new(response)
          cache_control.turn_on if Env.new(Api).production?
          if cache_control.on?
            if_none_match = request.env['HTTP_IF_NONE_MATCH']
            redis = CodePraise::Cache::Client.new(CodePraise::App.config)
            etag_key = "#{owner_name}_#{project_name}_etag"
            etag_value = redis.get(etag_key)

            if !if_none_match.nil? && !etag_value.nil? && if_none_match.include?(etag_value)
              response.status = 304
              return response.to_json
            end
          end

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
          elsif @processing.in_progress?
            view 'progress_bar', locals: { path: @path, processing: @processing,
                                           project_path: @project_path, panel_view: @panel_view }
          else
            if cache_control.on?
              etag_value = redis.get(etag_key)
              response['Etag'] = etag_value
            end
            view 'dashboard', locals: { path: @path, processing: @processing,
                                        project_path: @project_path, panel_view: @panel_view }
          end
        end
      end
    end
  end
end
