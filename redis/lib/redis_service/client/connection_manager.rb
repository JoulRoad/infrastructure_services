# frozen_string_literal: true

require "redis"
require "hiredis"
require "connection_pool"

module RedisService
  module Client
    # Connection manager with Single Responsibility for managing Redis connections
    class ConnectionManager
      attr_reader :configuration

      def initialize(configuration:)
        @configuration = configuration
        @read_pools = {}
        @write_pools = {}
        @mutex = Mutex.new
      end

      # Get or create a read connection pool for a given namespace
      def read_connection_pool_for(namespace = nil)
        @mutex.synchronize do
          @read_pools[namespace] ||= create_connection_pool(namespace, true)
        end
      end

      # Get or create a write connection pool for a given namespace
      def write_connection_pool_for(namespace = nil)
        @mutex.synchronize do
          @write_pools[namespace] ||= create_connection_pool(namespace, false)
        end
      end

      # Create a client for a namespace
      def client_for(namespace = nil, serializer: nil)
        read_pool = read_connection_pool_for(namespace)
        write_pool = write_connection_pool_for(namespace)
        
        RedisClient.new(
          read_connection_pool: read_pool,
          write_connection_pool: write_pool,
          namespace: namespace,
          serializer: serializer
        )
      end

      # Close all connections
      def close_all
        @mutex.synchronize do
          @read_pools.each_value(&:shutdown)
          @read_pools.clear
          
          @write_pools.each_value(&:shutdown)
          @write_pools.clear
        end
      end

      private

      # Create a connection pool with the specified configurations
      def create_connection_pool(namespace, for_read)
        namespace_config = namespace ? configuration.for_namespace(namespace) : configuration
        
        pool_size = namespace_config.pool_size
        pool_timeout = namespace_config.pool_timeout

        ConnectionPool.new(size: pool_size, timeout: pool_timeout) do
          create_redis_connection(namespace_config, for_read)
        end
      end

      # Create a raw Redis connection
      def create_redis_connection(config, for_read)
        options = build_connection_options(config, for_read)
        
        # Always use hiredis driver regardless of configuration
        options[:driver] = :hiredis

        begin
          Redis.new(options)
        rescue Redis::BaseError => e
          raise ConnectionError, "Failed to connect to Redis: #{e.message}"
        end
      end

      # Build connection options for Redis based on the configuration and type (read/write)
      def build_connection_options(config, for_read)
        # Common options for all connection types
        common_options = {
          timeout: config.timeout,
          connect_timeout: config.connect_timeout,
          read_timeout: config.read_timeout,
          write_timeout: config.write_timeout,
          reconnect_attempts: config.reconnect_attempts,
          reconnect_delay: config.reconnect_delay,
          ssl: config.ssl,
          ssl_params: config.ssl_params
        }

        # Determine the connection type and add the appropriate URL or host/port options
        connection_url = for_read ? config.read_url : config.write_url
        
        if connection_url
          # URL-based connection
          { url: connection_url }.merge(common_options)
        else
          # Standard host/port connection
          {
            host: config.host,
            port: config.port,
            db: config.db,
            password: config.password
          }.merge(common_options)
        end.compact
      end
    end
  end
end 