# frozen_string_literal: true

require_relative 'form_base'

module CodePraise
  module Forms
    # url request
    class UrlRequest < Dry::Validation::Contract
      config.messages.load_paths << File.join(__dir__, 'errors/url_request.yml')
      
      params do
        required(:remote_url).filled(format?: URL_REGEX)
      end
    end
  end
end
