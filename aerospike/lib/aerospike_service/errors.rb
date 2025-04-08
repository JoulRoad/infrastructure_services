# frozen_string_literal: true

module AerospikeService
  class Error < StandardError; end

  class ConfigError < Error; end

  class ConnectionError < Error; end

  class OperationError < Error; end

  class RecordNotFoundError < Error; end
end
