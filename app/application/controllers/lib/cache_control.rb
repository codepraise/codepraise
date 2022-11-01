# frozen_string_literal: true

module CodePraise
  module Cache
    # Helps the controller set and inspect cache
    class Control
      def initialize(response)
        @response = response
        @on = false
      end

      def turn_on
        @response.cache_control public: true, max_age: 0
        @on = true
      end

      def on?
        @on
      end
    end
  end
end
