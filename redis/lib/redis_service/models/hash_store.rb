# frozen_string_literal: true

module RedisService
  module Models
    # Model class for Redis hash operations, following the Single Responsibility Principle
    class HashStore
      attr_reader :client
      
      def initialize(client)
        @client = client
      end

      def get(hash_key, field)
        client.hashes.hget(hash_key, field)
      end

      def set(hash_key, field, value)
        client.hashes.hset(hash_key, field, value)
      end

      def delete(hash_key, field)
        client.hashes.hdel(hash_key, field)
      end

      def all(hash_key)
        client.hashes.hgetall(hash_key)
      end

      def keys(hash_key)
        all(hash_key).keys
      end

      def values(hash_key)
        all(hash_key).values
      end

      def field_exists?(hash_key, field)
        all(hash_key).key?(field.to_s)
      end

      def increment(hash_key, field, amount = 1)
        current = get(hash_key, field).to_i
        set(hash_key, field, current + amount)
        current + amount
      end

      def expire(hash_key, seconds)
        client.keys.expire(hash_key, seconds)
      end

      def ttl(hash_key)
        client.keys.ttl(hash_key)
      end
    end
  end
end 