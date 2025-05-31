# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RedisService do
  describe "configuration" do
    before(:each) do
      RedisService.reset!
    end

    it "can be configured programmatically" do
      RedisService.configure do |config|
        config.read_url = "redis://localhost:6379/14"
        config.write_url = "redis://localhost:6379/15"
        config.pool_size = 5
        config.reconnect_attempts = 3
      end

      config = RedisService.configuration
      expect(config.read_url).to eq("redis://localhost:6379/14")
      expect(config.write_url).to eq("redis://localhost:6379/15")
      expect(config.pool_size).to eq(5)
      expect(config.reconnect_attempts).to eq(3)
    end

    it "properly configures namespaces" do
      RedisService.configure do |config|
        config.read_url = "redis://localhost:6379/14"
        config.write_url = "redis://localhost:6379/15"
        config.namespaces = {
          "users" => { prefix: "users" },
          "orders" => { prefix: "orders" }
        }
      end

      config = RedisService.configuration
      expect(config.namespaces["users"]).to include(prefix: "users")
      expect(config.namespaces["orders"]).to include(prefix: "orders")

      # Test namespace client creation
      users_client = RedisService.namespace("users")
      expect(users_client).not_to be_nil
    end

    it "configures connection options" do
      RedisService.configure do |config|
        config.read_url = "redis://localhost:6379/14"
        config.write_url = "redis://localhost:6379/15"
        config.pool_size = 10
        config.pool_timeout = 5
        config.connect_timeout = 2
        config.read_timeout = 3
        config.reconnect_attempts = 5
      end

      config = RedisService.configuration
      expect(config.pool_size).to eq(10)
      expect(config.pool_timeout).to eq(5)
      expect(config.connect_timeout).to eq(2)
      expect(config.read_timeout).to eq(3)
      expect(config.reconnect_attempts).to eq(5)
    end

    it "always uses hiredis driver" do
      RedisService.configure do |config|
        config.read_url = "redis://localhost:6379/14"
        config.write_url = "redis://localhost:6379/15"
      end

      # The hiredis driver should be used regardless of configuration
      read_config = RedisService.configuration.for_namespace(:read) || RedisService.configuration
      write_config = RedisService.configuration.for_namespace(:write) || RedisService.configuration

      expect(read_config.driver).to eq(:hiredis)
      expect(write_config.driver).to eq(:hiredis)
    end
  end
end