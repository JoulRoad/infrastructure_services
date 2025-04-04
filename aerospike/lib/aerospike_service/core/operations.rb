# frozen_string_literal: true

module AerospikeService
  # Low-level operations for interacting with Aerospike
  # Handles the details of Aerospike operations
  class Operations
    # @return [AerospikeService::ConnectionManager] Connection manager
    attr_reader :connection_manager

    # Initialize a new Operations instance
    # @param connection_manager [AerospikeService::ConnectionManager] Connection manager
    def initialize(connection_manager)
      @connection_manager = connection_manager
    end

    # Get a record by key
    # @param key [String] Record key
    # @param namespace [String] Namespace to use
    # @param bin [String, Symbol, nil] Specific bin to retrieve, or nil for all bins
    # @return [Hash, nil] Record bins or nil if not found
    def get(key, namespace, bin = nil)
      connection_manager.with_client(namespace) do |client|
        record = client.get(aerospike_key(key, namespace), bin)
        record&.bins
      end
    rescue RecordNotFoundError
      nil
    end

    # Store a record
    # @param key [String] Record key
    # @param bins [Hash] Hash of bin names to values
    # @param namespace [String] Namespace to use
    # @param ttl [Integer, nil] Time to live in seconds, or nil for no expiration
    # @return [Boolean] true if successful
    def put(key, bins, namespace, ttl = nil)
      connection_manager.with_client(namespace) do |client|
        policy = ttl ? Aerospike::WritePolicy.new(ttl: ttl) : nil
        client.put(aerospike_key(key, namespace), bins, policy)
        true
      end
    end

    # Delete a record
    # @param key [String] Record key
    # @param namespace [String] Namespace to use
    # @return [Boolean] true if deleted, false if not found
    def delete(key, namespace)
      connection_manager.with_client(namespace) do |client|
        client.delete(aerospike_key(key, namespace))
        true
      end
    rescue RecordNotFoundError
      false
    end

    # Check if a record exists
    # @param key [String] Record key
    # @param namespace [String] Namespace to use
    # @return [Boolean] true if exists, false otherwise
    def exists?(key, namespace)
      connection_manager.with_client(namespace) do |client|
        client.exists(aerospike_key(key, namespace))
      end
    end

    # Update the record's time to live
    # @param key [String] Record key
    # @param namespace [String] Namespace to use
    # @param ttl [Integer, nil] New TTL in seconds, or nil for default
    # @return [Boolean] true if successful, false if not found
    def touch(key, namespace, ttl = nil)
      connection_manager.with_client(namespace) do |client|
        policy = ttl ? Aerospike::WritePolicy.new(ttl: ttl) : nil
        client.touch(aerospike_key(key, namespace), policy)
        true
      end
    rescue RecordNotFoundError
      false
    end

    # Increment a bin in a record
    # @param key [String] Record key
    # @param bin [String, Symbol] Bin to increment
    # @param value [Integer] Value to increment by
    # @param namespace [String] Namespace to use
    # @return [Boolean] true if successful
    def increment(key, bin, value, namespace)
      connection_manager.with_client(namespace) do |client|
        bin_name = bin.to_s
        client.add(aerospike_key(key, namespace), {bin_name => value})
        true
      end
    rescue RecordNotFoundError
      # Create the record if it doesn't exist
      put(key, {bin.to_s => value}, namespace)
    end

    # Get multiple records by keys
    # @param keys [Array<String>] Array of record keys
    # @param namespace [String] Namespace to use
    # @param bin [String, Symbol, nil] Specific bin to retrieve, or nil for all bins
    # @return [Hash] Hash of keys to record bins
    def batch_get(keys, namespace, bin = nil)
      return {} if keys.empty?

      connection_manager.with_client(namespace) do |client|
        # Convert all keys to Aerospike keys
        aero_keys = keys.map { |k| aerospike_key(k, namespace) }

        # Get records using batch operation
        records = client.batch_get(aero_keys, bin)

        # Convert results to a hash of original keys to bins
        result = {}
        records.each do |key, record|
          next unless key && record
          original_key = key.user_key.value
          result[original_key] = record.bins
        end

        result
      end
    end

    private

    # Create an Aerospike key
    # @param key [String] User key
    # @param namespace [String] Namespace
    # @return [Aerospike::Key] Aerospike key instance
    def aerospike_key(key, namespace)
      # Using nil for set name (no set)
      Aerospike::Key.new(namespace, nil, key.to_s)
    end
  end
end
