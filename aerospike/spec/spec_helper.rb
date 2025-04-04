# frozen_string_literal: true

require "bundler/setup"
require "aerospike_service"

# Enable code coverage if ENV var is set
if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"
    add_filter "/vendor/"
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally
  config.disable_monkey_patching!

  # Use expect syntax
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Setup test configuration
  config.before(:suite) do
    AerospikeService.configure do |c|
      c.hosts = [{host: "127.0.0.1", port: 3000}]
      c.default_namespace = "test"
    end
  end

  # Reset service between tests
  config.after(:each) do
    AerospikeService.reset!
  end
end
