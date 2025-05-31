# frozen_string_literal: true

require 'spec_helper'

# Shared examples for testing Redis operations with different URL configurations
RSpec.shared_examples "redis operations" do |scenario|
  let(:test_key) { "test_key_#{Time.now.to_i}" }
  let(:test_hash_key) { "test_hash_#{Time.now.to_i}" }
  let(:test_list_key) { "test_list_#{Time.now.to_i}" }
  let(:test_set_key) { "test_set_#{Time.now.to_i}" }
  let(:test_zset_key) { "test_zset_#{Time.now.to_i}" }

  before(:each) do
    RedisService.reset!

    # Configure RedisService with scenario-specific URLs
    if scenario == :single_url
      RedisService.configure do |config|
        config.read_url = "redis://localhost:6379/15"
        config.write_url = "redis://localhost:6379/15"
        config.pool_size = 2
      end
    else # :separate_urls
      RedisService.configure do |config|
        config.read_url = "redis://localhost:6379/14"
        config.write_url = "redis://localhost:6379/15"
        config.pool_size = 2
      end
    end

    # Clear the test databases
    client = RedisService.client
    client.with_read_connection { |redis| redis.flushdb }
    client.with_write_connection { |redis| redis.flushdb }
  end
end