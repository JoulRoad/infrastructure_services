# frozen_string_literal: true

module RedisService
  module Operations
    # Operations for Redis sorted sets
    class SortedSetOperations
      def initialize(client)
        @client = client
      end
      
      # Read Operations
      
      def zrange(key, start, stop, options = {})
        @client.with_read_connection do |redis|
          with_scores = options[:with_scores]
          
          if with_scores
            values = redis.zrange(@client.namespaced_key(key), start, stop, with_scores: true)
            
            result = []
            values.each do |member, score|
              result << [@client.serializer.deserialize(member), score.to_f]
            end
            result
          else
            values = redis.zrange(@client.namespaced_key(key), start, stop)
            values.map { |v| @client.serializer.deserialize(v) }
          end
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("zrange", e)
      end
      
      def zrevrange(key, start, stop, options = {})
        @client.with_read_connection do |redis|
          with_scores = options[:with_scores]
          
          if with_scores
            values = redis.zrevrange(@client.namespaced_key(key), start, stop, with_scores: true)
            
            result = []
            values.each do |member, score|
              result << [@client.serializer.deserialize(member), score.to_f]
            end
            result
          else
            values = redis.zrevrange(@client.namespaced_key(key), start, stop)
            values.map { |v| @client.serializer.deserialize(v) }
          end
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("zrevrange", e)
      end
      
      def zrangebyscore(key, min, max, options = {})
        @client.with_read_connection do |redis|
          if options[:with_scores]
            values = redis.zrangebyscore(@client.namespaced_key(key), min, max, with_scores: true)
            
            result = []
            values.each do |member, score|
              result << [@client.serializer.deserialize(member), score.to_f]
            end
            result
          else
            values = redis.zrangebyscore(@client.namespaced_key(key), min, max)
            values.map { |v| @client.serializer.deserialize(v) }
          end
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("zrangebyscore", e)
      end
      
      def zrevrangebyscore(key, max, min, options = {})
        @client.with_read_connection do |redis|
          if options[:with_scores]
            values = redis.zrevrangebyscore(@client.namespaced_key(key), max, min, with_scores: true)
            
            result = []
            values.each do |member, score|
              result << [@client.serializer.deserialize(member), score.to_f]
            end
            result
          else
            values = redis.zrevrangebyscore(@client.namespaced_key(key), max, min)
            values.map { |v| @client.serializer.deserialize(v) }
          end
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("zrevrangebyscore", e)
      end
      
      def zscore(key, member)
        serialized = @client.serializer.serialize(member)
        @client.with_read_connection do |redis|
          redis.zscore(@client.namespaced_key(key), serialized)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("zscore", e)
      end
      
      def zrank(key, member)
        serialized = @client.serializer.serialize(member)
        @client.with_read_connection do |redis|
          redis.zrank(@client.namespaced_key(key), serialized)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("zrank", e)
      end
      
      def zcard(key)
        @client.with_read_connection do |redis|
          redis.zcard(@client.namespaced_key(key))
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("zcard", e)
      end
      
      def zcount(key, min, max)
        @client.with_read_connection do |redis|
          redis.zcount(@client.namespaced_key(key), min, max)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("zcount", e)
      end
      
      def zscan(key, cursor, options = {})
        @client.with_read_connection do |redis|
          redis.zscan(@client.namespaced_key(key), cursor, options)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("zscan", e)
      end
      
      # Write Operations
      
      def zadd(key, score, member)
        serialized = @client.serializer.serialize(member)
        @client.with_write_connection do |redis|
          redis.zadd(@client.namespaced_key(key), score, serialized)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("zadd", e)
      end
      
      def zrem(key, member)
        serialized = @client.serializer.serialize(member)
        @client.with_write_connection do |redis|
          redis.zrem(@client.namespaced_key(key), serialized) > 0
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("zrem", e)
      end
      
      def zremrangebyrank(key, start, stop)
        @client.with_write_connection do |redis|
          redis.zremrangebyrank(@client.namespaced_key(key), start, stop)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("zremrangebyrank", e)
      end
      
      def zremrangebyscore(key, min, max)
        @client.with_write_connection do |redis|
          redis.zremrangebyscore(@client.namespaced_key(key), min, max)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("zremrangebyscore", e)
      end
      
      def zincrby(key, amount, member)
        serialized = @client.serializer.serialize(member)
        @client.with_write_connection do |redis|
          redis.zincrby(@client.namespaced_key(key), amount, serialized)
        end
      rescue Redis::BaseError => e
        @client.handle_redis_error("zincrby", e)
      end
    end
  end
end 