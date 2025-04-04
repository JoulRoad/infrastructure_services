# frozen_string_literal: true

module AerospikeService
  # High-level client for Aerospike operations
  # Provides a clean interface for interacting with Aerospike
  class Client
    # @return [AerospikeService::ConnectionManager] Connection manager
    attr_reader :connection_manager

    # @return [AerospikeService::Configuration] Configuration instance
    attr_reader :configuration

    # @return [AerospikeService::Operations] Operations instance
    attr_reader :operations

    # Initialize a new Client
    # @param configuration [AerospikeService::Configuration] Configuration instance
    def initialize(configuration)
      @configuration = configuration
      @connection_manager = ConnectionManager.new(configuration)
      @operations = Operations.new(@connection_manager)
    end

    # Get a record by key
    # @param key [String] Record key
    # @param namespace [String, nil] Namespace to use, or nil to use default
    # @param bin [String, Symbol, nil] Specific bin to retrieve, or nil for all bins
    # @return [Hash, nil] Record bins or nil if not found
    def get(key, namespace = nil, bin = nil)
      operations.get(key, namespace || configuration.default_namespace, bin)
    end

    # Store a record
    # @param key [String] Record key
    # @param bins [Hash] Hash of bin names to values
    # @param namespace [String, nil] Namespace to use, or nil to use default
    # @param ttl [Integer, nil] Time to live in seconds, or nil for no expiration
    # @return [Boolean] true if successful
    def put(key, bins, namespace = nil, ttl = nil)
      operations.put(key, bins, namespace || configuration.default_namespace, ttl)
    end

    # Delete a record
    # @param key [String] Record key
    # @param namespace [String, nil] Namespace to use, or nil to use default
    # @return [Boolean] true if deleted, false if not found
    def delete(key, namespace = nil)
      operations.delete(key, namespace || configuration.default_namespace)
    end

    # Check if a record exists
    # @param key [String] Record key
    # @param namespace [String, nil] Namespace to use, or nil to use default
    # @return [Boolean] true if exists, false otherwise
    def exists?(key, namespace = nil)
      operations.exists?(key, namespace || configuration.default_namespace)
    end

    # Update the record's time to live
    # @param key [String] Record key
    # @param namespace [String, nil] Namespace to use, or nil to use default
    # @param ttl [Integer] New TTL in seconds
    # @return [Boolean] true if successful, false if not found
    def touch(key, namespace = nil, ttl = nil)
      operations.touch(key, namespace || configuration.default_namespace, ttl)
    end

    # Increment a bin in a record
    # @param key [String] Record key
    # @param bin [String, Symbol] Bin to increment
    # @param value [Integer] Value to increment by, defaults to 1
    # @param namespace [String, nil] Namespace to use, or nil to use default
    # @return [Boolean] true if successful
    def increment(key, bin, value = 1, namespace = nil)
      operations.increment(key, bin, value, namespace || configuration.default_namespace)
    end

    # Get multiple records by keys
    # @param keys [Array<String>] Array of record keys
    # @param namespace [String, nil] Namespace to use, or nil to use default
    # @param bin [String, Symbol, nil] Specific bin to retrieve, or nil for all bins
    # @return [Hash] Hash of keys to record bins
    def batch_get(keys, namespace = nil, bin = nil)
      operations.batch_get(keys, namespace || configuration.default_namespace, bin)
    end

    # Get the raw Aerospike client for a specific namespace
    # Use this with caution as it bypasses the service's abstractions
    # @param namespace [String, nil] Namespace to use, or nil to use default
    # @return [Aerospike::Client] Raw Aerospike client instance
    def raw_client(namespace = nil)
      namespace ||= configuration.default_namespace
      connection_manager.with_client(namespace) { |client| client }
    end

    # Close all client connections
    # @return [void]
    def close
      connection_manager.close_all
    end
  end
end
