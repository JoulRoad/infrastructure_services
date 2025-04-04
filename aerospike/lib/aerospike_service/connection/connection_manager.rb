# frozen_string_literal: true

module AerospikeService
  # Manages connections to multiple Aerospike clusters
  # Each namespace can have its own connection to different hosts
  class ConnectionManager
    # @return [AerospikeService::Configuration] Configuration for all namespaces
    attr_reader :configuration

    # @param configuration [AerospikeService::Configuration] Configuration instance
    def initialize(configuration)
      @configuration = configuration
      @connections = {}
    end

    # Get a connection for a specific namespace
    # @param namespace [String] Namespace name
    # @return [AerospikeService::Connection] Connection for the namespace
    def connection_for(namespace)
      namespace ||= configuration.default_namespace

      @connections[namespace] ||= begin
        # Get namespace-specific config or fall back to default
        ns_config = if configuration.namespace_configs.key?(namespace)
          configuration.namespace_configs[namespace]
        else
          # If no specific config exists, use default hosts
          {hosts: configuration.hosts}.merge(configuration.default_connection_options)
        end

        Connection.new(OpenStruct.new(ns_config))
      end
    end

    # Execute a block with the client for a specific namespace
    # @param namespace [String] Namespace name
    # @yield [client] Aerospike client instance
    # @return [Object] Result of the block
    def with_client(namespace)
      connection_for(namespace).with_client do |client|
        yield client
      end
    end

    # Close all connections
    # @return [void]
    def close_all
      @connections.each_value(&:close)
      @connections.clear
    end
  end
end
