# RedisService

A comprehensive, production-ready service adapter for Redis database with Rails integration, built with SOLID design principles.

## Features

- **SOLID Design**: Built following SOLID principles for better maintainability and extensibility
- **Dependency Injection**: Clear interfaces with injectable dependencies
- **High Performance**: Connection pooling and optimized serialization
- **Comprehensive API**: Support for all Redis data structures
- **Namespace Support**: Isolate your keys in different namespaces
- **Rails Integration**: Easy setup with generators and configuration
- **Robust Error Handling**: Consistent error handling across all operations
- **Higher-level Models**: Object-oriented wrappers for Redis data types
- **Serialization**: JSON serialization by default with extensible interfaces

## Requirements

- Ruby 3.3.7 or later
- Rails 6.1 or later (for Rails integration)
- Redis 5.0 or later

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis_service', github: 'your-org/infrastructure_services', subdirectory: 'redis'
```

Then execute:

```bash
$ bundle install
```

## Configuration

Generate the configuration file:

```bash
$ rails generate redis_service:install
```

This will create:
- `config/redis_service.yml` - Configuration file for different environments
- `config/initializers/redis_service.rb` - Rails initializer with shortcuts

### Configuration Options

```yaml
development:
  host: localhost
  port: 6379
  db: 0
  pool_size: 5
  pool_timeout: 5.0
  namespaces:
    cache:
      db: 1
    sessions:
      db: 2
```

## Usage

### Basic Usage

```ruby
# Configure the service (if not using Rails)
RedisService.configure do |config|
  config.host = "redis.example.com"
  config.port = 6379
  config.db = 0
end

# Read a value
user_data = RedisService.get("user:123")

# Write a value
RedisService.set("user:123", { name: "John Doe", email: "john@example.com" })

# Set with expiration
RedisService.set("session:abc", { user_id: 123 }, expire_in: 3600) # 1 hour

# Delete a value
RedisService.delete("user:123")

# Check if a key exists
if RedisService.exists?("user:123")
  # Do something
end

# Increment a counter
RedisService.increment("counter:visits")
```

### Namespace Support

```ruby
# Get client for a specific namespace
cache = RedisService.namespace(:cache)

# Use namespace-specific client
cache.set("stats", { visits: 1000 })
stats = cache.get("stats")

# Keys are automatically namespaced
# The key "stats" becomes "cache:stats" in Redis
```

### Higher-level Models

RedisService provides object-oriented wrappers for Redis data structures:

#### Key-Value Store

```ruby
kv_store = RedisService.key_value_store(:users)
kv_store["user:123"] = { name: "John" }
user = kv_store["user:123"]
```

#### Hash Store

```ruby
hash_store = RedisService.hash_store(:users)
hash_store.set("user:123", "name", "John")
hash_store.set("user:123", "email", "john@example.com")
name = hash_store.get("user:123", "name")
user_data = hash_store.all("user:123")
```

#### Lists

```ruby
list = RedisService.list(:queue)
list.push_back("jobs", "job_id_123")
list.push_front("jobs", "urgent_job_456")
job_id = list.pop_front("jobs")
items = list.range("jobs", 0, -1)
```

#### Sets

```ruby
set = RedisService.set(:tags)
set.add("article:123:tags", "ruby")
set.add("article:123:tags", "redis")
tags = set.members("article:123:tags")
set.remove("article:123:tags", "redis")
```

#### Sorted Sets

```ruby
zset = RedisService.sorted_set(:leaderboard)
zset.add("scores", 100, "player:123")
zset.add("scores", 200, "player:456")
top_players = zset.range("scores", 0, 9, with_scores: true)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Testing

Run the test suite:

```bash
$ bundle exec rake test
```

Run with a specific Redis server:

```bash
$ REDIS_URL=redis://localhost:6379/0 bundle exec rake test
```

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT). 