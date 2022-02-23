# frozen_string_literal: true

require 'roda'
require 'delegate'
require 'figaro'

module CodePraise
  # Environment-specific configuration
  class App < Roda
    HOUR = 60 * 60
    DAY = 24 * HOUR
    MONTH = 30 * DAY
    plugin :environments

    Figaro.application = Figaro::Application.new(
      environment: environment.to_s,
      path: File.expand_path('config/secrets.yml')
    )
    Figaro.load

    def self.config
      Figaro.env
    end

    use Rack::Session::Cookie, secret: config.SESSION_SECRET,
                               expire_after: MONTH

    configure :development, :test do
      require 'pry'

      # Allows running reload! in pry to restart entire app
      def self.reload!
        exec 'pry -r ./init.rb'
      end
    end
  end
end
