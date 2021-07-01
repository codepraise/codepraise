# frozen_string_literal: true

require 'dry-validation'

module CodePraise
  # Form helpers
  module Forms
    URL_REGEX = %r{(http[s]?)\:\/\/(www.|)?github\.com\/.*\/.*(?<!git)}.freeze

    def self.validation_errors(validation)
      validation.errors.to_h.map { |k, v| [k, v].join(' ') }.join('; ')
    end

    def self.message_values(validation)
      validation.errors.to_h.values.join('; ')
    end
  end
end
