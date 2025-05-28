# frozen_string_literal: true

module RedisService
  module Configuration
    # Configuration class that follows the Single Responsibility Principle
    # by focusing solely on managing Redis connection settings
    class Config
      attr_accessor :host, :port, :db, :password, :read_url, :write_url,
                    :timeout, :connect_timeout, :read_timeout, :write_timeout,
                    :reconnect_attempts,:ssl,
                    :ssl_params, :pool_size, :pool_timeout,
                    :driver,:namespaces

      def initialize
        @host = "localhost"
        @port = 6379
        @db = 0
        @password = nil
        @read_url = nil
        @write_url = nil
        @timeout = 5.0
        @connect_timeout = 5.0
        @read_timeout = 5.0
        @write_timeout = 5.0
        @reconnect_attempts = 3
        # @reconnect_delay = 0.5
        @ssl = false
        @ssl_params = {}
        @pool_size = 5
        @pool_timeout = 5.0
        @driver = :hiredis_client  # Default to using hiredis driver
        @namespaces = {}
      end

      # Load configuration from a hash
      def from_hash(config_hash)
        config_hash.each do |key, value|
          setter = "#{key}="
          send(setter, value) if respond_to?(setter)
        end
        self
      end

      # Register a namespace with specific configuration
      def register_namespace(name, options = {})
        @namespaces[name.to_sym] = options
        self
      end

      # Get namespace-specific configuration
      def for_namespace(name)
        name = name.to_sym if name.is_a?(String)
        NamespaceConfig.new(self, @namespaces[name] || {})
      end

      # Get default Redis URL if neither read nor write URL is provided
      def default_redis_url
        auth_part = password ? "#{ERB::Util.url_encode(password)}@" : ""
        "redis://#{auth_part}#{host}:#{port}/#{db}"
      end
    end

    # A dedicated class for namespace-specific configuration
    # following the Open/Closed Principle by extending base configuration
    class NamespaceConfig
      attr_reader :base_config, :namespace_options

      def initialize(base_config, namespace_options)
        @base_config = base_config
        @namespace_options = namespace_options
      end

      def method_missing(method, *args, &block)
        if namespace_options.key?(method)
          namespace_options[method]
        else
          base_config.send(method, *args, &block)
        end
      end

      def respond_to_missing?(method, include_private = false)
        namespace_options.key?(method) || base_config.respond_to?(method, include_private)
      end
    end
  end
end 