# frozen_string_literal: true

module RedisService
  module Models
    # Model class for Redis set operations, following the Single Responsibility Principle
    class Set
      attr_reader :client
      
      def initialize(client)
        @client = client
      end

      def add(set_key, member)
        client.sets.sadd(set_key, member)
      end

      def remove(set_key, member)
        client.sets.srem(set_key, member)
      end

      def members(set_key)
        client.sets.smembers(set_key)
      end

      def includes?(set_key, member)
        serialized = client.serializer.serialize(member)
        client.with_connection do |redis|
          redis.sismember(client.namespaced_key(set_key), serialized)
        end
      end

      def length(set_key)
        members(set_key).length
      end

      def empty?(set_key)
        length(set_key) == 0
      end

      def clear(set_key)
        client.keys.delete(set_key)
      end

      def expire(set_key, seconds)
        client.keys.expire(set_key, seconds)
      end

      def ttl(set_key)
        client.keys.ttl(set_key)
      end
    end
  end
end 