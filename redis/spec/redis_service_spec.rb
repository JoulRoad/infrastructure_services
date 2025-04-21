# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RedisService do
  # Configuration tests
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
      # Create a client and inspect the underlying Redis connection
      RedisService.configure do |config|
        config.read_url = "redis://localhost:6379/14"
        config.write_url = "redis://localhost:6379/15"
      end
      
      # The hiredis driver should be used regardless of configuration
      client = RedisService.client
      client.with_read_connection do |redis|
        expect(redis.instance_variable_get(:@client).driver).to eq(:hiredis)
      end
      
      client.with_write_connection do |redis|
        expect(redis.instance_variable_get(:@client).driver).to eq(:hiredis)
      end
    end
  end
  
  # Shared examples for testing Redis operations with different URL configurations
  shared_examples "redis operations" do |scenario|
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
    
    describe "namespaces" do
      it "properly isolates keys between namespaces" do
        RedisService.configure do |config|
          config.namespaces = {
            "users" => { prefix: "users" },
            "orders" => { prefix: "orders" }
          }
        end
        
        users = RedisService.namespace("users")
        orders = RedisService.namespace("orders")
        
        # Set keys in each namespace
        users.set("123", { name: "Alice" })
        orders.set("123", { product: "Gadget" })
        
        if scenario == :separate_urls
          # Sync namespace data
          users.with_read_connection do |redis|
            users.with_write_connection do |write_redis|
              redis.set("users:123", write_redis.get("users:123"))
            end
          end
          
          orders.with_read_connection do |redis|
            orders.with_write_connection do |write_redis|
              redis.set("orders:123", write_redis.get("orders:123"))
            end
          end
        end
        
        # Keys with the same ID in different namespaces should have different values
        expect(users.get("123")).to eq({ "name" => "Alice" })
        expect(orders.get("123")).to eq({ "product" => "Gadget" })
      end
    end
    
    describe "transactions and pipelining" do
      it "executes transactions atomically" do
        RedisService.client.multi do |redis|
          redis.set(test_key, "value1")
          redis.incr(test_key)
        end
        
        if scenario == :separate_urls
          # Sync transaction results
          RedisService.client.with_read_connection do |redis|
            RedisService.client.with_write_connection do |write_redis|
              redis.set(test_key, write_redis.get(test_key))
            end
          end
        end
        
        # The second command fails because "value1" is not a number
        # But in a transaction, all commands are executed regardless
        expect(RedisService.exists?(test_key)).to be true
        expect(RedisService.get(test_key)).to eq("value1")
      end
      
      it "executes commands in pipeline" do
        RedisService.client.pipelined do |redis|
          redis.set(test_key, "pipeline_value")
          redis.set("#{test_key}_2", "second_value")
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
    
    describe "helper models" do
      it "provides a key-value store model" do
        kv_store = RedisService.key_value_store
        
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
        hash_store = RedisService.hash_store
        
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
  end
  
  describe "with separate URLs for read/write" do
    include_examples "redis operations", :separate_urls
  end
end 