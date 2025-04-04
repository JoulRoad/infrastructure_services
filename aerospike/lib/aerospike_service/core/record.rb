# frozen_string_literal: true

module AerospikeService
  # Wrapper for Aerospike records
  # Provides a more convenient interface for working with records
  class Record
    # @return [String] Key of the record
    attr_reader :key

    # @return [Hash] Bins of the record
    attr_reader :bins

    # @return [String] Namespace of the record
    attr_reader :namespace

    # Initialize a new Record
    # @param key [String] Record key
    # @param bins [Hash] Record bins
    # @param namespace [String] Namespace
    def initialize(key, bins, namespace)
      @key = key
      @bins = bins || {}
      @namespace = namespace
    end

    # Get a bin value
    # @param bin_name [String, Symbol] Bin name
    # @return [Object, nil] Bin value or nil if not found
    def [](bin_name)
      bins[bin_name.to_s]
    end

    # Set a bin value
    # @param bin_name [String, Symbol] Bin name
    # @param value [Object] Bin value
    # @return [Object] The value
    def []=(bin_name, value)
      bins[bin_name.to_s] = value
    end

    # Save the record
    # @param ttl [Integer, nil] Time to live in seconds, or nil for no expiration
    # @return [Boolean] true if successful
    def save(ttl = nil)
      AerospikeService.put(key, bins, namespace, ttl)
    end

    # Delete the record
    # @return [Boolean] true if deleted, false if not found
    def delete
      AerospikeService.delete(key, namespace)
    end

    # Increment a bin
    # @param bin_name [String, Symbol] Bin name
    # @param value [Integer] Value to increment by
    # @return [Boolean] true if successful
    def increment(bin_name, value = 1)
      AerospikeService.increment(key, bin_name, value, namespace)
    end

    # Check if the record exists
    # @return [Boolean] true if exists, false otherwise
    def exists?
      AerospikeService.exists?(key, namespace)
    end

    # Update the record's TTL
    # @param ttl [Integer] New TTL in seconds
    # @return [Boolean] true if successful, false if not found
    def touch(ttl = nil)
      AerospikeService.touch(key, namespace, ttl)
    end

    # Reload the record from the database
    # @return [self]
    def reload
      fresh_bins = AerospikeService.get(key, nil, namespace)
      @bins = fresh_bins || {}
      self
    end

    # Get a string representation of the record
    # @return [String]
    def to_s
      "#<AerospikeService::Record key=#{key.inspect} namespace=#{namespace.inspect} bins=#{bins.inspect}>"
    end

    # Inspect the record
    # @return [String]
    def inspect
      to_s
    end
  end
end
