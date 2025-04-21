# frozen_string_literal: true

require "redis"
require "hiredis"
require "connection_pool"
require "redis_service/version"
require "redis_service/errors"

require "redis_service/serialization/serializer_interface"
require "redis_service/serialization/json_serializer"

require "redis_service/configuration/config"

require "redis_service/operations/key_operations"
require "redis_service/operations/list_operations"
require "redis_service/operations/hash_operations"
require "redis_service/operations/set_operations"
require "redis_service/operations/sorted_set_operations"

require "redis_service/client/redis_client"
require "redis_service/client/connection_manager"

require "redis_service/models/key_value_store"
require "redis_service/models/hash_store"
require "redis_service/models/list"
require "redis_service/models/set"
require "redis_service/models/sorted_set"

# Main module serving as a facade to the Redis service functionality
module RedisService
  class << self
    # Configuration access
    def configuration
      @configuration ||= Configuration::Config.new
    end

    def configure
      yield configuration if block_given?
      reset_connections!
      true
    end

    # Connection management
    def connection_manager
      @connection_manager ||= Client::ConnectionManager.new(configuration: configuration)
    end

    # Client access for default namespace
    def client
      @client ||= connection_manager.client_for
    end

    # Get client for a specific namespace
    def namespace(name)
      @namespaced_clients ||= {}
      @namespaced_clients[name] ||= connection_manager.client_for(name)
    end

    # Delegate key operations to the default client's keys handler
    def get(key)
      client.keys.get(key)
    end

    def set(key, value, options = {})
      client.keys.set(key, value, options)
    end

    def delete(key)
      client.keys.delete(key)
    end

    def exists?(key)
      client.keys.exists?(key)
    end

    def expire(key, seconds)
      client.keys.expire(key, seconds)
    end

    def ttl(key)
      client.keys.ttl(key)
    end

    def increment(key, amount = 1)
      client.keys.increment(key, amount)
    end

    def decrement(key, amount = 1)
      client.keys.decrement(key, amount)
    end

    # Additional key operations
    def mget(*keys)
      client.keys.mget(*keys)
    end

    def mset(hash)
      client.keys.mset(hash)
    end

    def keys(pattern)
      client.keys.keys(pattern)
    end

    # Delegate list operations to the default client's lists handler
    def lpush(key, value)
      client.lists.lpush(key, value)
    end

    def rpush(key, value)
      client.lists.rpush(key, value)
    end

    def lpop(key)
      client.lists.lpop(key)
    end

    def rpop(key)
      client.lists.rpop(key)
    end

    def lrange(key, start, stop)
      client.lists.lrange(key, start, stop)
    end

    def llen(key)
      client.lists.llen(key)
    end

    # Delegate hash operations to the default client's hashes handler
    def hset(key, field, value)
      client.hashes.hset(key, field, value)
    end

    def hget(key, field)
      client.hashes.hget(key, field)
    end

    def hdel(key, field)
      client.hashes.hdel(key, field)
    end

    def hgetall(key)
      client.hashes.hgetall(key)
    end

    def hexists(key, field)
      client.hashes.hexists(key, field)
    end

    # Delegate set operations to the default client's sets handler
    def sadd(key, member)
      client.sets.sadd(key, member)
    end

    def srem(key, member)
      client.sets.srem(key, member)
    end

    def smembers(key)
      client.sets.smembers(key)
    end

    def sismember(key, member)
      client.sets.sismember(key, member)
    end

    # Delegate sorted set operations to the default client's sorted_sets handler
    def zadd(key, score, member)
      client.sorted_sets.zadd(key, score, member)
    end

    def zrange(key, start, stop, options = {})
      client.sorted_sets.zrange(key, start, stop, options)
    end

    def zrem(key, member)
      client.sorted_sets.zrem(key, member)
    end

    # Transaction support
    def multi(&block)
      client.multi(&block)
    end

    def pipelined(&block)
      client.pipelined(&block)
    end

    # Higher-level model factories
    def key_value_store_for(namespace = nil)
      @key_value_stores ||= {}
      @key_value_stores[namespace] ||= Models::KeyValueStore.new(namespace ? self.namespace(namespace) : client)
    end

    def hash_store_for(namespace = nil)
      @hash_stores ||= {}
      @hash_stores[namespace] ||= Models::HashStore.new(namespace ? self.namespace(namespace) : client)
    end

    def list_for(namespace = nil)
      @lists ||= {}
      @lists[namespace] ||= Models::List.new(namespace ? self.namespace(namespace) : client)
    end

    def set_for(namespace = nil)
      @sets ||= {}
      @sets[namespace] ||= Models::Set.new(namespace ? self.namespace(namespace) : client)
    end

    def sorted_set_for(namespace = nil)
      @sorted_sets ||= {}
      @sorted_sets[namespace] ||= Models::SortedSet.new(namespace ? self.namespace(namespace) : client)
    end

    # Reset all state
    def reset!
      reset_connections!
      reset_models!
      @configuration = nil
      true
    end

    # Reset only client connections
    def reset_connections!
      @connection_manager&.close_all
      @connection_manager = nil
      @client = nil
      @namespaced_clients = nil
    end

    # Reset only model caches
    def reset_models!
      @key_value_stores = nil
      @hash_stores = nil
      @lists = nil
      @sets = nil
      @sorted_sets = nil
    end
  end

  # Load Rails integration if Rails is defined
  require "redis_service/railtie" if defined?(Rails)
end 