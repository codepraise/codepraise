# frozen_string_literal: true

require 'roda'
require 'slim'
require 'slim/include'

module CodePraise
  # Web App
  class App < Roda
    include RouteHelper

    plugin :halt
    plugin :flash
    plugin :all_verbs
    plugin :multi_route
    plugin :caching
    plugin :static, ['/images']
    plugin :partials, views: 'app/presentation/views'
    plugin :render, engine: 'erb', views: 'app/presentation/views'
    plugin :assets, path: 'app/presentation/assets',
                    css: ['styles.css', 'dashboard.css', 'home.css',
                          'quality.css', 'productivity.css', 'overview.css', 'ownership.css',
                          'functionality.css', 'files.css', 'progress_bar.css'],
                    js: ['share.js', 'options.js', 'chart.js', 'dashboard.js',
                         'home.js', 'main.js']


    use Rack::MethodOverride

    route do |routing|
      routing.assets # load CSS

      # GET /
      routing.root do
        # Get cookie viewer's previously seen projects
        @path = 'root'
        session[:watching] ||= []

        result = Service::ListProjects.new.call(session[:watching])

        if result.failure?
          flash[:error] = result.failure
          projects = []
        else
          projects = result.value!.projects
          if projects.none?
            flash.now[:notice] = 'Add a Github project to get started'
          end
        end
        @example = App.config.APP_HOST + '/appraisal/codepraise/codepraise-api'
        session[:watching] = projects.map(&:fullname)
        @viewable_projects = Views::ProjectsList.new(projects)
        view 'home', locals: { projects: @viewable_projects, path: @path, example: @example }
      end

      routing.multi_route
    end
  end
end
