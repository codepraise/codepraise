# frozen_string_literal: true

module CodePraise
  class App < Roda
    plugin :multi_route

    route('project') do |routing|
      routing.is do
        # POST /project/
        routing.post do
          url_request = Forms::UrlRequest.call(routing.params)
          project_made = Service::AddProject.new.call(url_request)

          if project_made.failure?
            JsonResponse.new(project_made.failure).send(response)
          else
            result = project_made.value!
            project = result.message
            session[:watching].insert(0, project.fullname).uniq!
            JsonResponse.new(result).send(response, Representer::Project)
          end
        end
      end

      routing.on String, String do |owner_name, project_name|
        # DELETE /project/{owner_name}/{project_name}
        routing.delete do
          fullname = "#{owner_name}/#{project_name}"
          session[:watching].delete(fullname)

          routing.redirect '/'
        end

        # GET /project/{owner_name}/{project_name}[/folder_namepath/]
        routing.get do
          path_request = ProjectRequestPath.new(
            owner_name, project_name, request
          )

          session[:watching] ||= []

          result = Service::AppraiseProject.new.call(
            watched_list: session[:watching],
            requested: path_request
          )

          if result.failure?
            flash[:error] = result.failure
            routing.redirect '/'
          end

          appraisal = OpenStruct.new(result.value!)

          if appraisal.response.processing?
            flash.now[:notice] = 'Project is being cloned and analyzed'
          else
            appraised = appraisal.appraised
            proj_folder = Views::ProjectFolderContributions
              .new(appraised[:project], appraised[:folder])
            response.expires(60, public: true) if App.environment == :produciton
          end

          processing = Views::AppraisalProcessing.new(
            App.config, appraisal.response
          )

          # Show viewer the project
          view 'project', locals: { proj_folder: proj_folder,
                                    processing: processing }
        end
      end
    end
  end
end
