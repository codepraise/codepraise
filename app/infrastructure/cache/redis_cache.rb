# frozen_string_literal: true

require 'redis'
require 'connection_pool'

module CodePraise
  module Cache
    # Redis client utility
    class Client
      def initialize(config)
        @redis ||= ConnectionPool.new(size: 5, timeout: 5) do
          Redis.new(url: config.REDIS_URL)
        end
      end

      def keys
        @redis.keys
      end

      def get(key)
        @redis.get(key)
      end

      def set(key, value)
        @redis.set(key, value)
      end

      def wipe
        keys.each { |key| @redis.del(key) }
      end
    end
  end
end
