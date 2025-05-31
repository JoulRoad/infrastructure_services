# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples_spec'

RSpec.describe RedisService do
  shared_examples "transactions and pipelining" do |scenario|
    describe "transactions and pipelining" do
      it "executes transactions atomically" do
        begin
          RedisService.client.multi do |redis|
            redis.set(test_key, RedisService::Serialization::JsonSerializer.new.serialize("value1"))
            redis.incr(test_key)  # This should fail
          end
        rescue RedisService::OperationError => e
          expect(e.message).to include("ERR value is not an integer")
        end

        if scenario == :separate_urls
          # Sync transaction results from write to read
          RedisService.client.with_read_connection do |redis|
            RedisService.client.with_write_connection do |write_redis|
              redis.set(test_key, write_redis.get(test_key))
            end
          end
        end

        expect(RedisService.get(test_key)).to eq("value1")
      end

      it "executes commands in pipeline" do
        RedisService.client.pipelined do |redis|
          redis.set(test_key, RedisService::Serialization::JsonSerializer.new.serialize("pipeline_value"))
          redis.set("#{test_key}_2", RedisService::Serialization::JsonSerializer.new.serialize("second_value"))
        end

        if scenario == :separate_urls
          # Sync pipelined results
          RedisService.client.with_read_connection do |redis|
            RedisService.client.with_write_connection do |write_redis|
              redis.set(test_key, write_redis.get(test_key))
              redis.set("#{test_key}_2", write_redis.get("#{test_key}_2"))
            end
          end
        end

        expect(RedisService.get(test_key)).to eq("pipeline_value")
        expect(RedisService.get("#{test_key}_2")).to eq("second_value")
      end
    end
  end

  shared_examples "helper models" do |scenario|
    describe "helper models" do
      it "provides a key-value store model" do
        redis_client = RedisService.client
        kv_store = RedisService::Models::KeyValueStore.new(redis_client)

        kv_store["user"] = { name: "Eve" }

        if scenario == :separate_urls
          # Sync KV store data
          RedisService.client.with_read_connection do |redis|
            RedisService.client.with_write_connection do |write_redis|
              redis.set("user", write_redis.get("user"))
            end
          end
        end

        expect(kv_store["user"]).to eq({ "name" => "Eve" })
      end

      it "provides a hash store model" do
        redis_client = RedisService.client
        hash_store = RedisService::Models::HashStore.new(redis_client)

        hash_store.set("profiles", "user1", { role: "admin" })

        if scenario == :separate_urls
          # Sync hash store data
          RedisService.client.with_read_connection do |redis|
            RedisService.client.with_write_connection do |write_redis|
              redis.hset("profiles", "user1", write_redis.hget("profiles", "user1"))
            end
          end
        end

        expect(hash_store.get("profiles", "user1")).to eq({ "role" => "admin" })
      end
    end
  end

  describe "with single URL for read/write" do
    include_examples "redis operations", :single_url
    include_examples "transactions and pipelining", :single_url
    include_examples "helper models", :single_url
  end

  describe "with separate URLs for read/write" do
    include_examples "redis operations", :separate_urls
    include_examples "transactions and pipelining", :separate_urls
    include_examples "helper models", :separate_urls
  end
end