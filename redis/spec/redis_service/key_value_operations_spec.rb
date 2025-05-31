# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples_spec'

RSpec.describe RedisService do
  shared_examples "basic key-value operations" do |scenario|
    describe "basic key-value operations" do
      it "sets and gets string values" do
        RedisService.set(test_key, "test_value")

        if scenario == :single_url
          # With single URL, data should be immediately available
          expect(RedisService.get(test_key)).to eq("test_value")
        else
          # With separate URLs, simulate replication
          expect(RedisService.get(test_key)).to be_nil

          # Sync data between write and read databases
          value = RedisService.client.with_write_connection { |redis| redis.get(test_key) }
          RedisService.client.with_read_connection { |redis| redis.set(test_key, value) }

          # Now the value should be available
          expect(RedisService.get(test_key)).to eq("test_value")
        end
      end

      it "sets and gets complex objects with serialization" do
        user = { name: "John", email: "john@example.com", age: 30, active: true }
        RedisService.set("user:123", user)

        if scenario == :single_url
          # With single URL, data should be immediately available
          retrieved = RedisService.get("user:123")
          expect(retrieved["name"]).to eq("John")
          expect(retrieved["email"]).to eq("john@example.com")
          expect(retrieved["age"]).to eq(30)
          expect(retrieved["active"]).to be true
        else
          # With separate URLs, simulate replication
          expect(RedisService.get("user:123")).to be_nil

          # Sync data between write and read databases
          value = RedisService.client.with_write_connection { |redis| redis.get("user:123") }
          RedisService.client.with_read_connection { |redis| redis.set("user:123", value) }

          # Now the value should be available
          retrieved = RedisService.get("user:123")
          expect(retrieved["name"]).to eq("John")
          expect(retrieved["email"]).to eq("john@example.com")
          expect(retrieved["age"]).to eq(30)
          expect(retrieved["active"]).to be true
        end
      end

      it "deletes keys" do
        RedisService.set(test_key, "delete_me")

        if scenario == :separate_urls
          # Sync data for separate URLs
          value = RedisService.client.with_write_connection { |redis| redis.get(test_key) }
          RedisService.client.with_read_connection { |redis| redis.set(test_key, value) }
        end

        expect(RedisService.exists?(test_key)).to be true
        RedisService.delete(test_key)

        if scenario == :single_url
          expect(RedisService.exists?(test_key)).to be false
        else
          # For separate URLs, the delete happens on write but read might not be synced
          # Sync the deletion
          RedisService.client.with_read_connection { |redis| redis.del(test_key) }
          expect(RedisService.exists?(test_key)).to be false
        end
      end

      it "sets keys with expiration" do
        RedisService.set(test_key, "temp_value", expire_in: 1)

        if scenario == :separate_urls
          # Sync data for separate URLs
          value = RedisService.client.with_write_connection { |redis| redis.get(test_key) }
          ttl = RedisService.client.with_write_connection { |redis| redis.ttl(test_key) }
          RedisService.client.with_read_connection { |redis| redis.setex(test_key, ttl, value) }
        end

        expect(RedisService.get(test_key)).to eq("temp_value")

        # Wait for expiration
        sleep 1.5

        expect(RedisService.get(test_key)).to be_nil
      end

      it "increments and decrements counters" do
        RedisService.set(test_key, 10)

        if scenario == :separate_urls
          # Sync initial value for separate URLs
          value = RedisService.client.with_write_connection { |redis| redis.get(test_key) }
          RedisService.client.with_read_connection { |redis| redis.set(test_key, value) }
        end

        expect(RedisService.increment(test_key)).to eq(11)
        expect(RedisService.increment(test_key, 5)).to eq(16)

        if scenario == :separate_urls
          # Sync incremented value
          value = RedisService.client.with_write_connection { |redis| redis.get(test_key) }
          RedisService.client.with_read_connection { |redis| redis.set(test_key, value) }
        end

        expect(RedisService.decrement(test_key)).to eq(15)
        expect(RedisService.decrement(test_key, 5)).to eq(10)

        if scenario == :separate_urls
          # Sync decremented value
          value = RedisService.client.with_write_connection { |redis| redis.get(test_key) }
          RedisService.client.with_read_connection { |redis| redis.set(test_key, value) }
        end

        expect(RedisService.get(test_key)).to eq(10)
      end
    end
  end

  describe "with single URL for read/write" do
    include_examples "redis operations", :single_url
    include_examples "basic key-value operations", :single_url
  end

  describe "with separate URLs for read/write" do
    include_examples "redis operations", :separate_urls
    include_examples "basic key-value operations", :separate_urls
  end
end