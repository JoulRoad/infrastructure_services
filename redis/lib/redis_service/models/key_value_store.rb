# frozen_string_literal: true

module RedisService
  module Models
    # Model class for key-value operations, following the Single Responsibility Principle
    class KeyValueStore
      attr_reader :client

      def initialize(client)
        @client = client
      end

      def [](key)
        client.keys.get(key)
      end

      def []=(key, value)
        client.keys.set(key, value)
      end

      def get(key)
        client.keys.get(key)
      end

      def set(key, value, **options)
        client.keys.set(key, value, **options)
      end

      def delete(key)
        client.keys.delete(key)
      end

      def exists?(key)
        client.keys.exists?(key)
      end

      def expire(key, seconds)
        client.keys.expire(key, seconds)
      end

      def ttl(key)
        client.keys.ttl(key)
      end

      def increment(key, amount = 1)
        client.keys.increment(key, amount)
      end

      def decrement(key, amount = 1)
        client.keys.decrement(key, amount)
      end
    end
  end
end 