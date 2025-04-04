# frozen_string_literal: true

require "rails/railtie"

module AerospikeService
  # Rails integration for AerospikeService
  class Railtie < Rails::Railtie
    # Configure generators
    config.aerospike_service = ActiveSupport::OrderedOptions.new

    initializer "aerospike_service.initialize" do |app|
      # Load Aerospike configuration from config file
      config_file = Rails.root.join("config", "aerospike_service.yml")
      if File.exist?(config_file)
        AerospikeService.load_configuration(config_file)
      end

      # Set up logger
      AerospikeService.configuration.logger = Rails.logger

      # Add templates path for generators
      if app.config.respond_to?(:generators)
        app.config.generators.templates.unshift(
          File.expand_path("../../templates", __dir__)
        )
      end

      # Handle application shutdown - close all connections
      app.config.after_initialize do
        ActiveSupport.on_load(:before_terminate_connection_pool) do
          AerospikeService.client.close
        end
      end
    end

    # Register generators
    generators do
      require "aerospike_service/generators/install_generator"
      require "aerospike_service/generators/shortcuts_generator"
      require "aerospike_service/generators/bundle_config_generator"
      require "aerospike_service/generators/setup_generator"
    end
  end
end
