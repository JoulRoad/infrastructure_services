# AerospikeService

A comprehensive, production-ready service adapter for Aerospike database with Rails integration.

## Features

- Easy integration with Rails applications
- Connection pooling for improved performance
- Robust error handling and logging
- Configuration via YAML files
- Support for multiple namespaces
- Convenient shortcut generators
- Comprehensive documentation and testing

## Requirements

- Ruby 3.3.7 or later
- Rails 6.1 or later (for Rails integration)
- Aerospike database server

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aerospike_service', github: 'your-org/infrastructure_services', subdirectory: 'aerospike'
```

Then execute:

```bash
$ bundle install
```

## Configuration

Generate the configuration file:

```bash
$ rails generate aerospike_service:install
```

This will create:
- `config/aerospike_service.yml` - Configuration file
- `config/initializers/aerospike_service.rb` - Rails initializer

### Configuration Options

```yaml
development:
  hosts:
    - host: "127.0.0.1"
      port: 3000
  namespaces:
    - test
    - development
  default_namespace: test
  connection_timeout: 1.0
  socket_timeout: 0.5
  total_timeout: 2.0
  pool_size: 5
  pool_timeout: 5.0
```

## Usage

### Basic Usage

```ruby
# Configure the service (if not using Rails)
AerospikeService.configure do |config|
  config.hosts = [{ host: "aerospike.example.com", port: 3000 }]
  config.default_namespace = "my_namespace"
end

# Read a value
user_data = AerospikeService.get("user:123")

# Write a value
AerospikeService.put("user:123", { name: "John Doe", email: "john@example.com" })

# Delete a value
AerospikeService.delete("user:123")

# Check if a key exists
if AerospikeService.exists?("user:123")
  # Do something
end

# Increment a counter
AerospikeService.increment("counter:visits", "count", 1)

# Get multiple records at once
users = AerospikeService.batch_get(["user:123", "user:456"])
```

### Using Records

```ruby
# Create a record
record = AerospikeService::Record.new("user:123", { name: "John" }, "users")

# Update a record
record["email"] = "john@example.com"
record.save

# Reload data from database
record.reload

# Delete a record
record.delete
```

### Namespace Shortcuts

Generate namespace shortcuts:

```bash
$ rails generate aerospike_service:shortcuts
```

This creates a convenience module that allows you to access specific namespaces directly:

```ruby
# Access the 'users' namespace
Aerospike::Users.get("123")
Aerospike::Users.put("123", { name: "John Doe" })

# Access the 'analytics' namespace
Aerospike::Analytics.increment("daily:visits", "count")
```

## Development

After checking out the repo, run `bin/setup` to install dependencies and 
verify your Aerospike environment. Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt to experiment with the gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Testing

Run the test suite:

```bash
$ bundle exec rake test
```

Run the linter:

```bash
$ bundle exec rake lint
```

Generate documentation:

```bash
$ bundle exec rake doc:generate
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
