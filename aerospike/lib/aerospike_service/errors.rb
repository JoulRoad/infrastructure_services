# frozen_string_literal: true

module AerospikeService
  # Base error class for all AerospikeService errors
  class Error < StandardError; end

  # Configuration errors
  class ConfigError < Error; end

  # Connection errors
  class ConnectionError < Error; end

  # Operation errors
  class OperationError < Error; end

  # Record not found
  class RecordNotFoundError < Error; end
end
