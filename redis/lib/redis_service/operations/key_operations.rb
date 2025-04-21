# frozen_string_literal: true

module RedisService
  module Operations
    # Operations for basic key-value functionality
    class KeyOperations
      def initialize(client)
        @client = client
      end
      
      # Read Operations
      
      def get(key)
        @client.with_read_connection do |redis|
          value = redis.get(@client.namespaced_key(key))
          @client.serializer.deserialize(value) if value
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("get", e)
      end

      def exists?(key)
        @client.with_read_connection do |redis|
          redis.exists?(@client.namespaced_key(key))
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("exists?", e)
      end
      
      def ttl(key)
        @client.with_read_connection do |redis|
          redis.ttl(@client.namespaced_key(key))
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("ttl", e)
      end
      
      def keys(pattern)
        @client.with_read_connection do |redis|
          redis.keys(@client.namespaced_key(pattern))
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("keys", e)
      end
      
      def type(key)
        @client.with_read_connection do |redis|
          redis.type(@client.namespaced_key(key))
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("type", e)
      end
      
      def scan(key, *args)
        @client.with_read_connection do |redis|
          redis.scan(@client.namespaced_key(key), *args)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("scan", e)
      end
      
      def mget(*keys)
        @client.with_read_connection do |redis|
          namespaced_keys = keys.map { |k| @client.namespaced_key(k) }
          values = redis.mget(*namespaced_keys)
          values.map { |v| @client.serializer.deserialize(v) if v }
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("mget", e)
      end
      
      # Write Operations
      
      def set(key, value, options = {})
        serialized = @client.serializer.serialize(value)
        @client.with_write_connection do |redis|
          if options.empty?
            redis.set(@client.namespaced_key(key), serialized)
          else
            args = {}
            args[:ex] = options[:expire_in].to_i if options[:expire_in]
            args[:nx] = true if options[:nx]
            args[:xx] = true if options[:xx]
            args[:keepttl] = true if options[:keepttl]
            redis.set(@client.namespaced_key(key), serialized, **args)
          end
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("set", e)
      end
      
      def setnx(key, value)
        serialized = @client.serializer.serialize(value)
        @client.with_write_connection do |redis|
          redis.setnx(@client.namespaced_key(key), serialized)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("setnx", e)
      end
      
      def setex(key, ttl, value)
        serialized = @client.serializer.serialize(value)
        @client.with_write_connection do |redis|
          redis.setex(@client.namespaced_key(key), ttl, serialized)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("setex", e)
      end

      def delete(key)
        @client.with_write_connection do |redis|
          redis.del(@client.namespaced_key(key)) > 0
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("delete", e)
      end
      
      def del(key)
        delete(key)
      end

      def expire(key, seconds)
        @client.with_write_connection do |redis|
          redis.expire(@client.namespaced_key(key), seconds)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("expire", e)
      end

      def increment(key, amount = 1)
        @client.with_write_connection do |redis|
          redis.incrby(@client.namespaced_key(key), amount)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("increment", e)
      end
      
      def incr(key)
        @client.with_write_connection do |redis|
          redis.incr(@client.namespaced_key(key))
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("incr", e)
      end
      
      def incrby(key, amount)
        increment(key, amount)
      end

      def decrement(key, amount = 1)
        @client.with_write_connection do |redis|
          redis.decrby(@client.namespaced_key(key), amount)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("decrement", e)
      end
      
      def decrby(key, amount)
        decrement(key, amount)
      end
      
      def mset(*args)
        @client.with_write_connection do |redis|
          # Namespace the keys in the args array (every other element is a key)
          namespaced_args = []
          args.each_with_index do |arg, index|
            if index.even?
              namespaced_args << @client.namespaced_key(arg)
            else
              namespaced_args << @client.serializer.serialize(arg)
            end
          end
          redis.mset(*namespaced_args)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("mset", e)
      end
      
      def mapped_mset(hash)
        @client.with_write_connection do |redis|
          namespaced_hash = {}
          hash.each do |key, value|
            namespaced_hash[@client.namespaced_key(key)] = @client.serializer.serialize(value)
          end
          redis.mapped_mset(namespaced_hash)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("mapped_mset", e)
      end
    end
  end
end 