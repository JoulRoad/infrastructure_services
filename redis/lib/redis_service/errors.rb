# frozen_string_literal: true

module RedisService
  class Error < StandardError; end
  class ConnectionError < Error; end
  class OperationError < Error; end
  class ConfigurationError < Error; end
  class SerializationError < Error; end
end 