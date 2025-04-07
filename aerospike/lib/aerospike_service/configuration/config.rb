# frozen_string_literal: true

module AerospikeService
  module Configuration
    class Config
      attr_accessor :hosts, :default_namespace, :namespaces,
        :namespace_configs, :connect_timeout,
        :timeout, :max_retries, :max_connections

      def initialize
        @hosts = [{host: "127.0.0.1", port: 3000}]
        @default_namespace = "test"
        @namespaces = ["test"]
        @namespace_configs = {}
        @connect_timeout = 1.0
        @timeout = 1.0
        @max_retries = 2
        @max_connections = 10
      end

      # Get the hosts configuration for a specific namespace
      def hosts_for(namespace:)
        namespace_configs.dig(namespace, "hosts") || hosts
      end

      # Parse a host string into a hash
      def parse_host(host_string:)
        if host_string.include?(":")
          host, port = host_string.split(":")
          host = "127.0.0.1" if host == "localhost"
          {host: host, port: port.to_i}
        else
          host = host_string == "localhost" ? "127.0.0.1" : host_string
          {host: host, port: 3000}
        end
      end
    end
  end
end
