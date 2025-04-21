# frozen_string_literal: true

module RedisService
  module Models
    # Model class for Redis list operations, following the Single Responsibility Principle
    class List
      attr_reader :client
      
      def initialize(client)
        @client = client
      end

      def push_front(list_key, value)
        client.lists.lpush(list_key, value)
      end

      def push_back(list_key, value)
        client.lists.rpush(list_key, value)
      end

      def pop_front(list_key)
        client.lists.lpop(list_key)
      end

      def pop_back(list_key)
        client.lists.rpop(list_key)
      end

      def range(list_key, start = 0, stop = -1)
        client.lists.lrange(list_key, start, stop)
      end

      def length(list_key)
        range(list_key).length
      end

      def empty?(list_key)
        length(list_key) == 0
      end

      def clear(list_key)
        client.keys.delete(list_key)
      end

      def expire(list_key, seconds)
        client.keys.expire(list_key, seconds)
      end

      def ttl(list_key)
        client.keys.ttl(list_key)
      end
    end
  end
end 