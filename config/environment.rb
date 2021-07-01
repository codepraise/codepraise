# frozen_string_literal: true

require 'roda'
require 'econfig'
require 'delegate'

module CodePraise
  # Environment-specific configuration
  class App < Roda
    HOUR = 60 * 60
    DAY = 24 * HOUR
    MONTH = 30 * DAY
    plugin :environments

    extend Econfig::Shortcut
    Econfig.env = environment.to_s
    Econfig.root = '.'

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
