# frozen_string_literal: true

require 'bundler/setup'
require 'redis_service'
require 'connection_pool'
require 'redis'

# Configure RSpec
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Use the specified formatter
  config.formatter = :documentation

  # Run specs in random order
  config.order = :random
  Kernel.srand config.seed

  # Expectations syntax
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end

  # Mock syntax
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Reset RedisService before each test
  config.before(:each) do
    RedisService.reset! if defined?(RedisService)
  end
end

# Set default environment variables for tests if not already set
ENV['REDIS_READ_URL'] ||= 'redis://localhost:6379/14'
ENV['REDIS_WRITE_URL'] ||= 'redis://localhost:6379/15' 