# frozen_string_literal: true

require "redis"
require "hiredis"
require "connection_pool"

module RedisService
  module Client
    # Redis client implementation with optional read/write separation
    # This client can connect to different servers for read and write operations
    class RedisClient
      attr_reader :namespace, :serializer, :read_pool, :write_pool
      
      def initialize(read_connection_pool:, write_connection_pool:, namespace: nil, serializer: nil)
        @read_pool = read_connection_pool
        @write_pool = write_connection_pool 
        @namespace = namespace
        @serializer = serializer || Serialization::JsonSerializer.new
        @operations = {}
      end
      
      # Accessor for key operations (get, set, etc.)
      def keys
        @operations[:keys] ||= Operations::KeyOperations.new(self)
      end
      
      # Accessor for list operations (lpush, rpop, etc.)
      def lists
        @operations[:lists] ||= Operations::ListOperations.new(self)
      end
      
      # Accessor for hash operations (hset, hget, etc.)
      def hashes
        @operations[:hashes] ||= Operations::HashOperations.new(self)
      end
      
      # Accessor for set operations (sadd, smembers, etc.)
      def sets
        @operations[:sets] ||= Operations::SetOperations.new(self)
      end
      
      # Accessor for sorted set operations (zadd, zrange, etc.)
      def sorted_sets
        @operations[:sorted_sets] ||= Operations::SortedSetOperations.new(self)
      end
      
      # Execute a block with a read connection
      def with_read_connection(&block)
        @read_pool.with(&block)
      end
      
      # Execute a block with a write connection
      def with_write_connection(&block)
        @write_pool.with(&block)
      end
      
      # Execute a block with a connection (defaults to read for backward compatibility)
      def with_connection(&block)
        with_read_connection(&block)
      end
      
      # Execute a Redis command on the read connection
      def read_execute(command, *args, **kwargs)
        with_read_connection do |redis|
          redis.public_send(command, *args, **kwargs)
        end
      rescue Redis::BaseError => e
        handle_redis_error(command, e)
      end
      
      # Execute a Redis command on the write connection
      def write_execute(command, *args, **kwargs)
        with_write_connection do |redis|
          redis.public_send(command, *args, **kwargs)
        end
      rescue Redis::BaseError => e
        handle_redis_error(command, e)
      end
      
      # Helper method for namespacing keys
      def namespaced_key(key)
        namespace ? "#{namespace}:#{key}" : key.to_s
      end
      
      # Helper method for error handling
      def handle_redis_error(operation, error)
        if error.is_a?(Redis::TimeoutError) || error.is_a?(Redis::CannotConnectError)
          raise ConnectionError, "Redis connection error during #{operation}: #{error.message}"
        else
          raise OperationError, "Redis error during #{operation}: #{error.message}"
        end
      end
      
      # Support for pipelined operations (on write connection)
      def pipelined(&block)
        with_write_connection do |redis|
          redis.pipelined(&block)
        end
      rescue Redis::BaseError => e
        handle_redis_error("pipelined", e)
      end
      
      # Support for transactions (on write connection)
      def multi(&block)
        with_write_connection do |redis|
          redis.multi(&block)
        end
      rescue Redis::BaseError => e
        handle_redis_error("multi", e)
      end
    end
  end
end 