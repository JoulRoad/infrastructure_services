# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples_spec'

RSpec.describe RedisService do
  shared_examples "hash operations" do |scenario|
    describe "hash operations" do
      it "sets and gets hash fields" do
        RedisService.hset(test_hash_key, "name", "Alice")
        RedisService.hset(test_hash_key, "email", "alice@example.com")

        if scenario == :separate_urls
          # Sync hash data
          RedisService.client.with_read_connection do |redis|
            RedisService.client.with_write_connection do |write_redis|
              redis.hset(test_hash_key, "name", write_redis.hget(test_hash_key, "name"))
              redis.hset(test_hash_key, "email", write_redis.hget(test_hash_key, "email"))
            end
          end
        end

        expect(RedisService.hget(test_hash_key, "name")).to eq("Alice")
        expect(RedisService.hgetall(test_hash_key)).to include("name" => "Alice", "email" => "alice@example.com")

        RedisService.hdel(test_hash_key, "email")

        if scenario == :separate_urls
          # Sync deletion
          RedisService.client.with_read_connection do |redis|
            redis.hdel(test_hash_key, "email")
          end
        end

        expect(RedisService.hgetall(test_hash_key)).to eq({"name" => "Alice"})
      end
    end
  end

  describe "with single URL for read/write" do
    include_examples "redis operations", :single_url
    include_examples "hash operations", :single_url
  end

  describe "with separate URLs for read/write" do
    include_examples "redis operations", :separate_urls
    include_examples "hash operations", :separate_urls
  end
end