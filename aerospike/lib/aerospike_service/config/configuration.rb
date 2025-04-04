# frozen_string_literal: true

require "yaml"
require "active_support/core_ext/hash/indifferent_access"
require "active_model"

module AerospikeService
  # Configuration for AerospikeService
  # Handles loading configuration from YAML and providing defaults
  class Configuration
    include ActiveModel::Validations

    # @!attribute [rw] hosts
    #   @return [Array<Hash>] List of default Aerospike hosts to connect to
    attr_accessor :hosts

    # @!attribute [rw] namespaces
    #   @return [Array<String>] List of available Aerospike namespaces
    attr_accessor :namespaces

    # @!attribute [rw] default_namespace
    #   @return [String] Default namespace to use when none is specified
    attr_accessor :default_namespace

    # @!attribute [rw] namespace_configs
    #   @return [Hash] Namespace-specific configurations
    attr_accessor :namespace_configs

    # @!attribute [rw] connection_timeout
    #   @return [Float] Default timeout for initial connection in seconds
    attr_accessor :connection_timeout

    # @!attribute [rw] socket_timeout
    #   @return [Float] Default timeout for socket operations in seconds
    attr_accessor :socket_timeout

    # @!attribute [rw] total_timeout
    #   @return [Float] Default total timeout for operations in seconds
    attr_accessor :total_timeout

    # @!attribute [rw] pool_size
    #   @return [Integer] Default size of the connection pool
    attr_accessor :pool_size

    # @!attribute [rw] pool_timeout
    #   @return [Float] Default timeout for acquiring a connection from the pool
    attr_accessor :pool_timeout

    # @!attribute [rw] logger
    #   @return [Logger] Logger instance for AerospikeService
    attr_accessor :logger

    validates :hosts, presence: true
    validates :default_namespace, presence: true
    validates :connection_timeout, :socket_timeout, :total_timeout,
      numericality: {greater_than: 0}
    validates :pool_size, numericality: {greater_than: 0, only_integer: true}
    validates :pool_timeout, numericality: {greater_than_or_equal_to: 0}

    # Initialize a new Configuration instance with default values
    def initialize
      # Default configuration values
      @hosts = [{host: "127.0.0.1", port: 3000}]
      @namespaces = ["test"]
      @default_namespace = "test"
      @namespace_configs = {}

      # Default connection options
      @connection_timeout = 1.0  # seconds
      @socket_timeout = 0.5      # seconds
      @total_timeout = 2.0       # seconds
      @pool_size = 5             # connections
      @pool_timeout = 5.0        # seconds
      @logger = defined?(Rails) ? Rails.logger : Logger.new($stdout)
    end

    # Get default connection options
    # @return [Hash] Default connection options
    def default_connection_options
      {
        connection_timeout: @connection_timeout,
        socket_timeout: @socket_timeout,
        total_timeout: @total_timeout,
        pool_size: @pool_size,
        pool_timeout: @pool_timeout,
        logger: @logger
      }
    end

    # Load configuration from a YAML file
    # @param config_file [String, Pathname] Path to the YAML configuration file
    # @return [self]
    def load(config_file = nil)
      config_file ||= Rails.root.join("config", "aerospike_service.yml") if defined?(Rails)
      return self unless config_file && File.exist?(config_file)

      yaml_config = YAML.load_file(config_file)
      environment = defined?(Rails) ? Rails.env : ENV["RACK_ENV"] || ENV["RAILS_ENV"] || "development"
      config = yaml_config[environment] || yaml_config

      # Use HashWithIndifferentAccess for string/symbol key access
      config = ActiveSupport::HashWithIndifferentAccess.new(config)

      # Update configuration properties
      @hosts = parse_hosts(config[:hosts]) if config[:hosts]
      @namespaces = config[:namespaces] if config[:namespaces]
      @default_namespace = config[:default_namespace] if config[:default_namespace]
      @connection_timeout = config[:connection_timeout] if config[:connection_timeout]
      @socket_timeout = config[:socket_timeout] if config[:socket_timeout]
      @total_timeout = config[:total_timeout] if config[:total_timeout]
      @pool_size = config[:pool_size] if config[:pool_size]
      @pool_timeout = config[:pool_timeout] if config[:pool_timeout]

      # Handle namespace-specific configurations
      if config[:namespace_configs].is_a?(Hash)
        config[:namespace_configs].each do |namespace, ns_config|
          @namespace_configs[namespace.to_s] = ActiveSupport::HashWithIndifferentAccess.new

          # Process namespace hosts
          if ns_config[:hosts]
            @namespace_configs[namespace.to_s][:hosts] = parse_hosts(ns_config[:hosts])
          end

          # Copy other namespace settings
          [:connection_timeout, :socket_timeout, :total_timeout, :pool_size, :pool_timeout].each do |option|
            if ns_config[option]
              @namespace_configs[namespace.to_s][option] = ns_config[option]
            end
          end
        end
      end

      # Make sure all namespaces are in the namespaces list
      @namespaces |= @namespace_configs.keys

      # Validate configuration
      validate!

      self
    end

    # Validate the configuration and raise an error if invalid
    # @raise [ConfigurationError] if the configuration is invalid
    # @return [Boolean] true if valid
    def validate!
      unless valid?
        error_messages = errors.full_messages.join(", ")
        raise ConfigurationError, "Invalid configuration: #{error_messages}"
      end

      true
    end

    private

    # Parse hosts from various formats into a consistent structure
    # @param hosts_config [Array, String] Host configuration in various formats
    # @return [Array<Hash>] Array of host hashes with host and port keys
    def parse_hosts(hosts_config)
      return [{host: "127.0.0.1", port: 3000}] unless hosts_config

      Array(hosts_config).map do |host_config|
        if host_config.is_a?(String)
          host, port = host_config.split(":")
          {host: host, port: port&.to_i || 3000}
        else
          {
            host: host_config[:host] || host_config["host"],
            port: (host_config[:port] || host_config["port"] || 3000).to_i
          }
        end
      end
    end
  end
end
