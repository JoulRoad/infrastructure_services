# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples_spec'

RSpec.describe RedisService do
  shared_examples "list operations" do |scenario|
    describe "list operations" do
      it "handles basic list operations" do
        RedisService.lpush(test_list_key, "item1")
        RedisService.rpush(test_list_key, "item2")

        if scenario == :separate_urls
          # Sync list data
          RedisService.client.with_read_connection do |redis|
            redis.del(test_list_key)
            RedisService.client.with_write_connection do |write_redis|
              write_redis.lrange(test_list_key, 0, -1).each do |item|
                redis.rpush(test_list_key, item)
              end
            end
          end
        end

        expect(RedisService.lrange(test_list_key, 0, -1)).to eq(["item1", "item2"])
        expect(RedisService.lpop(test_list_key)).to eq("item1")

        if scenario == :separate_urls
          # Sync pop operation
          RedisService.client.with_read_connection do |redis|
            redis.del(test_list_key)
            RedisService.client.with_write_connection do |write_redis|
              write_redis.lrange(test_list_key, 0, -1).each do |item|
                redis.rpush(test_list_key, item)
              end
            end
          end
        end

        expect(RedisService.rpop(test_list_key)).to eq("item2")
      end
    end
  end

  shared_examples "set operations" do |scenario|
    describe "set operations" do
      it "handles basic set operations" do
        RedisService.sadd(test_set_key, "member1")
        RedisService.sadd(test_set_key, "member2")
        RedisService.sadd(test_set_key, "member1") # duplicates are ignored

        if scenario == :separate_urls
          # Sync set data
          RedisService.client.with_read_connection do |redis|
            redis.del(test_set_key)
            RedisService.client.with_write_connection do |write_redis|
              write_redis.smembers(test_set_key).each do |member|
                redis.sadd(test_set_key, member)
              end
            end
          end
        end

        expect(RedisService.smembers(test_set_key).sort).to eq(["member1", "member2"])

        RedisService.srem(test_set_key, "member1")

        if scenario == :separate_urls
          # Sync removal
          RedisService.client.with_read_connection do |redis|
            redis.del(test_set_key)
            RedisService.client.with_write_connection do |write_redis|
              write_redis.smembers(test_set_key).each do |member|
                redis.sadd(test_set_key, member)
              end
            end
          end
        end

        expect(RedisService.smembers(test_set_key)).to eq(["member2"])
      end
    end
  end

  shared_examples "sorted set operations" do |scenario|
    describe "sorted set operations" do
      it "handles basic sorted set operations" do
        RedisService.zadd(test_zset_key, 100, "player1")
        RedisService.zadd(test_zset_key, 200, "player2")

        if scenario == :separate_urls
          # Sync sorted set data
          RedisService.client.with_read_connection do |redis|
            redis.del(test_zset_key)
            RedisService.client.with_write_connection do |write_redis|
              write_redis.zrange(test_zset_key, 0, -1, with_scores: true).each do |member, score|
                redis.zadd(test_zset_key, score, member)
              end
            end
          end
        end

        result = RedisService.zrange(test_zset_key, 0, -1, with_scores: true)
        expect(result).to eq([["player1", 100.0], ["player2", 200.0]])
      end
    end
  end

  describe "with single URL for read/write" do
    include_examples "redis operations", :single_url
    include_examples "list operations", :single_url
    include_examples "set operations", :single_url
    include_examples "sorted set operations", :single_url
  end

  describe "with separate URLs for read/write" do
    include_examples "redis operations", :separate_urls
    include_examples "list operations", :separate_urls
    include_examples "set operations", :separate_urls
    include_examples "sorted set operations", :separate_urls
  end
end