# frozen_string_literal: true

require "aerospike"
require "aerospike_service/version"
require "aerospike_service/errors"
require "aerospike_service/configuration/config"
require "aerospike_service/configuration/loader"
require "aerospike_service/operations/read_operations"
require "aerospike_service/operations/write_operations"
require "aerospike_service/operations/batch_operations"
require "aerospike_service/client/connection_manager"
require "aerospike_service/client/base_client"
require "aerospike_service/client/namespace_client"

module AerospikeService
  class << self
    # Configuration access
    def configuration
      @configuration ||= Configuration::Config.new
    end

    def configure
      yield configuration if block_given?
      self
    end

    def load_configuration(file_path:)
      Configuration::Loader.load(file_path: file_path, config: configuration)
      self
    end

    # Connection management
    def connection_manager
      @connection_manager ||= Client::ConnectionManager.new(configuration: configuration)
    end

    # Namespace access
    def namespace(name:)
      Client::NamespaceClient.new(namespace_name: name.to_s)
    end

    # Client access
    def client
      @client ||= Client::BaseClient.new
    end

    # Delegate to client for operations
    def method_missing(method, ...)
      if client.respond_to?(method)
        client.send(method, ...)
      elsif configuration.namespaces.include?(method.to_s)
        namespace(name: method)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      client.respond_to?(method) ||
        configuration.namespaces.include?(method.to_s) ||
        super
    end

    # Reset all state
    def reset!
      @configuration = nil
      @client = nil
      @connection_manager&.close_all
      @connection_manager = nil
    end
  end

  # Load Rails integration if Rails is defined
  require "aerospike_service/railtie" if defined?(Rails)
end
