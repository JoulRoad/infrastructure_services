# frozen_string_literal: true

module AerospikeService
  module Client
    class ConnectionManager
      attr_reader :configuration, :connections

      def initialize(configuration:)
        @configuration = configuration
        @connections = {}
        @mutex = Mutex.new
      end

      def connection_for(namespace)
        @mutex.synchronize do
          @connections[namespace] ||= create_connection(namespace)
        end
      end

      def close_all
        @mutex.synchronize do
          @connections.each_value(&:close)
          @connections.clear
        end
      end

      private

      def create_connection(namespace)
        hosts = configuration.hosts_for(namespace: namespace)
        client_policy = Aerospike::ClientPolicy.new
        client_policy.timeout = configuration.timeout if client_policy.respond_to?(:timeout=)

        begin
          aerospike_hosts = hosts.map do |h|
            host = h.is_a?(Hash) ? (h[:host] || h["host"]) : h[:host]
            port = h.is_a?(Hash) ? (h[:port] || h["port"]) : h[:port]

            Aerospike::Host.new(host, port)
          end

          Aerospike::Client.new(aerospike_hosts, policy: client_policy)
        rescue => e
          raise ConnectionError, "Failed to connect to Aerospike cluster: #{e.message}"
        end
      end
    end
  end
end
