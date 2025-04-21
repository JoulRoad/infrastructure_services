# frozen_string_literal: true

module RedisService
  module Models
    # Model class for Redis sorted set operations, following the Single Responsibility Principle
    class SortedSet
      attr_reader :client
      
      def initialize(client)
        @client = client
      end

      def add(zset_key, score, member)
        client.sorted_sets.zadd(zset_key, score, member)
      end

      def remove(zset_key, member)
        serialized = client.serializer.serialize(member)
        client.with_connection do |redis|
          redis.call("ZREM", client.namespaced_key(zset_key), serialized) > 0
        end
      end

      def range(zset_key, start = 0, stop = -1, with_scores: false)
        client.sorted_sets.zrange(zset_key, start, stop, with_scores: with_scores)
      end

      def score(zset_key, member)
        serialized = client.serializer.serialize(member)
        client.with_connection do |redis|
          score = redis.zscore(client.namespaced_key(zset_key), serialized)
          score&.to_f
        end
      end

      def rank(zset_key, member)
        serialized = client.serializer.serialize(member)
        client.with_connection do |redis|
          redis.zrank(client.namespaced_key(zset_key), serialized)
        end
      end

      def length(zset_key)
        client.with_connection do |redis|
          redis.zcard(client.namespaced_key(zset_key))
        end
      end

      def empty?(zset_key)
        length(zset_key) == 0
      end

      def clear(zset_key)
        client.keys.delete(zset_key)
      end

      def expire(zset_key, seconds)
        client.keys.expire(zset_key, seconds)
      end

      def ttl(zset_key)
        client.keys.ttl(zset_key)
      end
    end
  end
end 