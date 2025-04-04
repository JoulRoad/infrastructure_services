# frozen_string_literal: true

require "aerospike"
require "connection_pool"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/module/delegation"

require_relative "aerospike_service/version"
require_relative "aerospike_service/errors"
require_relative "aerospike_service/config/configuration"
require_relative "aerospike_service/connection/connection"
require_relative "aerospike_service/connection/connection_manager"
require_relative "aerospike_service/core/client"
require_relative "aerospike_service/core/operations"
require_relative "aerospike_service/core/record"

# Load Rails integration if Rails is available
require_relative "aerospike_service/rails/railtie" if defined?(Rails)

# AerospikeService provides a high-level interface for working with Aerospike databases
# in a Ruby or Rails application, with a focus on simplicity, performance, and reliability.
module AerospikeService
  class << self
    # @return [AerospikeService::Configuration] the current configuration instance
    def configuration
      @configuration ||= Configuration.new
    end

    # Configure the AerospikeService
    # @yield [config] Configuration instance for setting up the service
    # @example
    #   AerospikeService.configure do |config|
    #     config.hosts = [{ host: "aerospike.example.com", port: 3000 }]
    #     config.default_namespace = "my_namespace"
    #   end
    def configure
      yield(configuration) if block_given?
      @client = nil  # Reset client so it's recreated with new configuration
      configuration
    end

    # Load configuration from a YAML file
    # @param config_file [String, Pathname] Path to the YAML configuration file
    # @return [AerospikeService::Configuration] the updated configuration
    def load_configuration(config_file = nil)
      configuration.load(config_file)
      @client = nil  # Reset client so it's recreated with new configuration
      configuration
    end

    # Access the Aerospike client instance
    # @return [AerospikeService::Client] the client instance
    def client
      @client ||= Client.new(configuration)
    end

    # Reset the client and configuration (useful for testing)
    # @return [void]
    def reset!
      @configuration = nil
      @client = nil
    end

    # Delegates missing methods to the client instance
    # @param method_name [Symbol] Method name to delegate
    # @param args Arguments to pass to the method
    # @param block Block to pass to the method
    def method_missing(method_name, *, &)
      if client.respond_to?(method_name)
        client.send(method_name, *, &)
      else
        super
      end
    end

    # @param method_name [Symbol] Method name to check
    # @param include_private [Boolean] Whether to include private methods
    # @return [Boolean] Whether the client responds to the method
    def respond_to_missing?(method_name, include_private = false)
      client.respond_to?(method_name) || super
    end
  end
end
