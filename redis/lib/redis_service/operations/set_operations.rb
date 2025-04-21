# frozen_string_literal: true

module RedisService
  module Operations
    # Operations for Redis sets
    class SetOperations
      def initialize(client)
        @client = client
      end
      
      # Read Operations
      
      def smembers(key)
        @client.with_read_connection do |redis|
          values = redis.smembers(@client.namespaced_key(key))
          values.map { |v| @client.serializer.deserialize(v) }
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("smembers", e)
      end
      
      def sismember(key, member)
        serialized = @client.serializer.serialize(member)
        @client.with_read_connection do |redis|
          redis.sismember(@client.namespaced_key(key), serialized)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("sismember", e)
      end
      
      def scard(key)
        @client.with_read_connection do |redis|
          redis.scard(@client.namespaced_key(key))
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("scard", e)
      end
      
      def srandmember(key, count = nil)
        @client.with_read_connection do |redis|
          if count
            values = redis.srandmember(@client.namespaced_key(key), count)
            values.map { |v| @client.serializer.deserialize(v) }
          else
            value = redis.srandmember(@client.namespaced_key(key))
            @client.serializer.deserialize(value) if value
          end
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("srandmember", e)
      end
      
      # Write Operations
      
      def sadd(key, member)
        serialized = @client.serializer.serialize(member)
        @client.with_write_connection do |redis|
          redis.sadd(@client.namespaced_key(key), serialized) > 0
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("sadd", e)
      end

      def srem(key, member)
        serialized = @client.serializer.serialize(member)
        @client.with_write_connection do |redis|
          redis.srem(@client.namespaced_key(key), serialized) > 0
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("srem", e)
      end
      
      def spop(key)
        @client.with_write_connection do |redis|
          value = redis.spop(@client.namespaced_key(key))
          @client.serializer.deserialize(value) if value
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("spop", e)
      end
    end
  end
end 