# frozen_string_literal: true

# Configure AerospikeService
# This initializer loads configuration and sets up the service

# Load the config file
config_file = Rails.root.join("config", "aerospike_service.yml")

# Configure the service
AerospikeService.configure do |config|
  # Load from config file if it exists
  if File.exist?(config_file)
    config.load(config_file)
  else
    # Default configuration if file doesn't exist
    config.hosts = [{ host: ENV.fetch("AEROSPIKE_HOST", "127.0.0.1"), port: ENV.fetch("AEROSPIKE_PORT", 3000).to_i }]
    config.namespaces = [Rails.env]
    config.default_namespace = Rails.env
    
    # Example of namespace-specific configuration
    config.namespace_configs = {
      Rails.env => {
        hosts: [{ host: ENV.fetch("AEROSPIKE_HOST", "127.0.0.1"), port: ENV.fetch("AEROSPIKE_PORT", 3000).to_i }]
      }
    }
  end
  
  # Always use Rails logger
  config.logger = Rails.logger
end

# Log startup information
Rails.logger.info "AerospikeService initialized with hosts: #{AerospikeService.configuration.hosts.inspect}"