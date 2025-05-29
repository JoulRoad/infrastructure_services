# frozen_string_literal: true

require "bundler/setup"
require "aerospike_service"
require "yaml"
require '../lib/aerospike_service'
require '../lib/aerospike_service/config/config_selector'

# Configure for testing
ENV["RACK_ENV"] = "test"

# Load test configuration
#config_file = File.join(File.dirname(__FILE__), "config", "aerospike_service.yml")
#fallback_file = File.join(File.dirname(__FILE__), "config", "aerospike_static.yml")

mode = 'zookeeper' #yml/zookeepr
selected_source = Config::ConfigSelector.setup(mode)

if selected_source.should_convert?
  config = selected_source.convert_config
  AerospikeService.load_configuration(file_path: config)
else
  raise "Selected config mode #{mode} is invalid or misconfigured."
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset AerospikeService between tests
  config.before(:each) do
    AerospikeService.reset!
    if Config::BaseConfig.should_convert?
      config_file = Config::BaseConfig.convert
      AerospikeService.load_configuration(file_path: config_file)
    else
      raise "No valid config"
    end
    #AerospikeService.load_configuration(file_path: config_file) #if File.exist?(config_file)
  end
end

# Helper for cleaning up test data
def clean_test_data(namespace = nil)
  namespaces = namespace ? [namespace] : AerospikeService.configuration.namespaces

  namespaces.each do |ns|
    # Delete any test keys
    # Implementation depends on your test approach
  end
end
