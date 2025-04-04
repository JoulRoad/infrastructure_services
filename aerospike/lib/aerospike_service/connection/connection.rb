# frozen_string_literal: true

require "connection_pool"

module AerospikeService
  # Manages connections to Aerospike database
  # Uses connection pooling for better performance
  class Connection
    # @return [AerospikeService::Configuration] Configuration for this connection
    attr_reader :configuration

    # @param configuration [AerospikeService::Configuration] Configuration instance
    def initialize(configuration)
      @configuration = configuration
      @pool = create_connection_pool
    end

    # Retrieves a connection from the pool and executes the given block
    # @yield [client] Aerospike client instance
    # @return [Object] Result of the block
    def with_client
      @pool.with do |client|
        yield client
      rescue Aerospike::Exceptions::Aerospike => e
        convert_aerospike_error(e)
      end
    end

    # Closes all connections in the pool
    # @return [void]
    def close
      @pool.shutdown { |client| client.close if client && !client.closed? }
    end

    # Checks if all connections in the pool are closed
    # @return [Boolean] true if all connections are closed
    def closed?
      # Implementation is approximate since we can't directly query the pool's state

      @pool.with do |client|
        return client.nil? || client.closed?
      end
    rescue
      true
    end

    # Creates a new connection pool with Aerospike clients
    # @return [ConnectionPool] Connection pool of Aerospike clients
    private def create_connection_pool
      ConnectionPool.new(size: configuration.pool_size, timeout: configuration.pool_timeout) do
        create_client
      end
    end

    # Creates a new Aerospike client
    # @return [Aerospike::Client] Aerospike client instance
    private def create_client
      hosts = configuration.hosts.map do |host_config|
        Aerospike::Host.new(host_config[:host], host_config[:port])
      end

      policy = Aerospike::ClientPolicy.new
      policy.timeout = configuration.connection_timeout
      policy.socket_timeout = configuration.socket_timeout
      policy.total_timeout = configuration.total_timeout

      # Setup logger
      policy.logger = configuration.logger

      begin
        Aerospike::Client.new(hosts, policy: policy)
      rescue Aerospike::Exceptions::Aerospike => e
        raise ConnectionError, "Failed to connect to Aerospike: #{e.message}"
      rescue => e
        raise ConnectionError, "Unexpected error connecting to Aerospike: #{e.message}"
      end
    end

    # Converts Aerospike errors to AerospikeService errors
    # @param error [Aerospike::Exceptions::Aerospike] Original Aerospike error
    # @raise [AerospikeService::Error] AerospikeService specific error
    private def convert_aerospike_error(error)
      case error
      when Aerospike::Exceptions::RecordNotFound
        raise RecordNotFoundError, error.message
      when Aerospike::Exceptions::Timeout
        raise TimeoutError, "Operation timed out: #{error.message}"
      when Aerospike::Exceptions::InvalidHostError
        raise ConnectionError, "Invalid host: #{error.message}"
      when Aerospike::Exceptions::InvalidNodeError
        raise ConnectionError, "Invalid node: #{error.message}"
      when Aerospike::Exceptions::ConnectionError
        raise ConnectionError, "Connection error: #{error.message}"
      when Aerospike::Exceptions::ServerError
        raise Error, "Server error: #{error.message}"
      when Aerospike::Exceptions::ParamError
        raise DataError, "Parameter error: #{error.message}"
      else
        raise Error, "Aerospike error: #{error.message}"
      end
    end
  end
end
