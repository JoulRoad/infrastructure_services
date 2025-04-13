# Infrastructure Services

A collection of service-oriented Ruby gems for integrating with various infrastructure components in modern applications. These gems follow SOLID principles and provide high-performance, maintainable abstractions.

## Available Services

Currently, this repository includes the following services:

### 🔴 RedisService

A service-oriented adapter for Redis with read/write separation, connection pooling, and comprehensive data structure support.

**Key Features:**
- Read/write connection separation for primary/replica architectures
- Automatic connection pooling for thread safety
- Built-in serialization via JSON
- High-performance operations using the hiredis driver
- Namespace support for key isolation
- Higher-level data structure abstractions

[View Redis Service Documentation](./redis/README.md)

### 🔷 AerospikeService

A service-oriented adapter for Aerospike database with namespace management and simplified operations.

**Key Features:**
- Simplified interface to Aerospike operations
- Namespace and set management
- Automatic serialization
- Connection configuration
- Record lifecycle management

[View Aerospike Service Documentation](./aerospike/README.md)

## Installation

Each service is packaged as a separate gem. Add the gems you need to your application's Gemfile:

```ruby
# For Redis support
gem 'redis_service'

# For Aerospike support
gem 'aerospike_service'
```

Then run:

```bash
bundle install
```

## Getting Started

After installation, you'll need to configure each service. The gems provide generators to create configuration files:

### Redis Service

```bash
rails generate redis_service:install
```

This will create:
- `config/initializers/redis_service.rb` - Main configuration
- `config/initializers/redis_shortcuts.rb` - Optional shortcuts

### Aerospike Service

```bash
rails generate aerospike_service:install
```

This will create:
- `config/initializers/aerospike_service.rb` - Main configuration
- `config/initializers/aerospike_shortcuts.rb` - Optional shortcuts (if requested)

## Development

### Setup

Clone the repository:

```bash
git clone https://github.com/JoulRoad/infrastructure_services.git
cd infrastructure_services
```

### Working with individual services

Each service is in its own directory with independent setup and tests:

```bash
cd redis  # or cd aerospike
bin/setup  # installs dependencies and prepares the environment
```

### Running External Services

Before running tests, ensure you have the necessary external services running. Each service requires its respective backing infrastructure:

```bash
# For Redis Service tests
docker run -d -p 6379:6379 --name redis-test redis:latest

# For Aerospike Service tests
docker run -d -p 3000:3000 --name aerospike-test aerospike/aerospike-server:latest
```

Then run the tests:

```bash
bundle exec rspec
```

### Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Create a new Pull Request

## License

All services in this repository are available as open source under the terms of the [MIT License](LICENSE).