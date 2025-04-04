# frozen_string_literal: true

module AerospikeService
  # Base error class for all AerospikeService errors
  class Error < StandardError; end

  # Error raised when there's a problem with the configuration
  class ConfigurationError < Error; end

  # Error raised when there's a problem connecting to the Aerospike server
  class ConnectionError < Error; end

  # Error raised when a record is not found
  class RecordNotFoundError < Error; end

  # Error raised when there's a timeout
  class TimeoutError < Error; end

  # Error raised when there's a problem with the data
  class DataError < Error; end
end
