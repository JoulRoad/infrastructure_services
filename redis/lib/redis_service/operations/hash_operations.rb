# frozen_string_literal: true

module RedisService
  module Operations
    # Operations for Redis hashes
    class HashOperations
      def initialize(client)
        @client = client
      end
      
      # Read Operations
      
      def hget(key, field)
        @client.with_read_connection do |redis|
          value = redis.hget(@client.namespaced_key(key), field)
          @client.serializer.deserialize(value) if value
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("hget", e)
      end

      def hgetall(key)
        @client.with_read_connection do |redis|
          hash = redis.hgetall(@client.namespaced_key(key))
          return {} if hash.empty?

          result = {}
          hash.each do |k, v|
            result[k] = @client.serializer.deserialize(v)
          end
          result
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("hgetall", e)
      end
      
      def hexists(key, field)
        @client.with_read_connection do |redis|
          redis.hexists(@client.namespaced_key(key), field)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("hexists", e)
      end
      
      def hlen(key)
        @client.with_read_connection do |redis|
          redis.hlen(@client.namespaced_key(key))
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("hlen", e)
      end
      
      def hkeys(key)
        @client.with_read_connection do |redis|
          redis.hkeys(@client.namespaced_key(key))
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("hkeys", e)
      end
      
      def hmget(key, *fields)
        @client.with_read_connection do |redis|
          values = redis.hmget(@client.namespaced_key(key), *fields)
          values.map { |v| @client.serializer.deserialize(v) if v }
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("hmget", e)
      end
      
      def hscan(key, cursor, options = {})
        @client.with_read_connection do |redis|
          redis.hscan(@client.namespaced_key(key), cursor, options)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("hscan", e)
      end
      
      # Write Operations
      
      def hset(key, field, value)
        serialized = @client.serializer.serialize(value)
        @client.with_write_connection do |redis|
          redis.hset(@client.namespaced_key(key), field, serialized)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("hset", e)
      end
      
      def hsetnx(key, field, value)
        serialized = @client.serializer.serialize(value)
        @client.with_write_connection do |redis|
          redis.hsetnx(@client.namespaced_key(key), field, serialized)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("hsetnx", e)
      end

      def hdel(key, field)
        @client.with_write_connection do |redis|
          redis.hdel(@client.namespaced_key(key), field) > 0
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("hdel", e)
      end
      
      def hmset(key, *attrs)
        @client.with_write_connection do |redis|
          # Process attrs to convert values to serialized form
          # Every other item is a field name, followed by a value
          namespaced_key = @client.namespaced_key(key)
          serialized_attrs = []
          attrs.each_with_index do |attr, index|
            if index.even?
              serialized_attrs << attr
            else
              serialized_attrs << @client.serializer.serialize(attr)
            end
          end
          redis.hmset(namespaced_key, *serialized_attrs)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("hmset", e)
      end
      
      def hincrby(key, field, amount)
        @client.with_write_connection do |redis|
          redis.hincrby(@client.namespaced_key(key), field, amount)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("hincrby", e)
      end
    end
  end
end 