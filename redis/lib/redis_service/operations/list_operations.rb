# frozen_string_literal: true

module RedisService
  module Operations
    # Operations for Redis lists
    class ListOperations
      def initialize(client)
        @client = client
      end
      
      # Read Operations
      
      def lindex(key, index)
        @client.with_read_connection do |redis|
          value = redis.lindex(@client.namespaced_key(key), index)
          @client.serializer.deserialize(value) if value
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("lindex", e)
      end
      
      def lrange(key, start, stop)
        @client.with_read_connection do |redis|
          values = redis.lrange(@client.namespaced_key(key), start, stop)
          values.map { |v| @client.serializer.deserialize(v) }
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("lrange", e)
      end
      
      def lpop(key)
        @client.with_read_connection do |redis|
          value = redis.lpop(@client.namespaced_key(key))
          @client.serializer.deserialize(value) if value
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("lpop", e)
      end

      def rpop(key)
        @client.with_read_connection do |redis|
          value = redis.rpop(@client.namespaced_key(key))
          @client.serializer.deserialize(value) if value
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("rpop", e)
      end
      
      # Write Operations
      
      def lpush(key, *values)
        @client.with_write_connection do |redis|
          serialized_values = values.map { |v| @client.serializer.serialize(v) }
          redis.lpush(@client.namespaced_key(key), *serialized_values)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("lpush", e)
      end

      def rpush(key, *values)
        @client.with_write_connection do |redis|
          serialized_values = values.map { |v| @client.serializer.serialize(v) }
          redis.rpush(@client.namespaced_key(key), *serialized_values)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("rpush", e)
      end
    end
  end
end 