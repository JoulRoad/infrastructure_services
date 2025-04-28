# frozen_string_literal: true

module RedisService
  # Rails integration following the Open/Closed Principle
  class Railtie < Rails::Railtie
    initializer "redis_service.initialize" do |app|
      # Note: RedisService needs to be configured programmatically in an initializer
      # Create config/initializers/redis_service.rb with your configuration:
      #
      # Example:
      # RedisService.configure do |config|
      #   config.read_url = ENV["REDIS_READ_URL"]
      #   config.write_url = ENV["REDIS_WRITE_URL"]
      #   config.pool_size = ENV.fetch("REDIS_POOL_SIZE", 5).to_i
      # end
      
      Rails.logger.info "RedisService will use programmatic configuration from initializers"
      
      # Set up auto-shutdown on Rails app termination
      app.config.after_initialize do
        at_exit do
          RedisService.connection_manager.close_all if defined?(RedisService.connection_manager)
        end
      end
    end
    
    # Define generators
    generators do
      require "redis_service/generators/install_generator"
    end
  end
end 