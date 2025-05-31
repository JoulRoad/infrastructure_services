# frozen_string_literal: true

require_relative "lib/redis_service/version"

Gem::Specification.new do |spec|
  spec.name = "redis_service"
  spec.version = RedisService::VERSION
  spec.authors = ["V-Mart"]
  spec.email = ["kumar.vaishnav@limeroad.com"]
  spec.license = "MIT"

  spec.summary = "Redis integration for Rails applications"
  spec.description = "A service-oriented adapter for Redis with Rails integration, following SOLID principles for high performance and reliability"
  spec.homepage = "https://github.com/JoulRoad/infrastructure_services"
  spec.required_ruby_version = ">= 3.3.7"

  spec.metadata = {
    "homepage_uri" => "#{spec.homepage}/tree/main/redis",
    "source_code_uri" => "#{spec.homepage}/tree/main/redis",
    "changelog_uri" => "#{spec.homepage}/blob/main/redis/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  # Specify which files should be included (be explicit)
  spec.files = Dir[
    "lib/**/*.rb",
    "lib/**/*.yml",
    "lib/**/*.tt",
    "bin/*",
    "README.md",
    "LICENSE.txt",
    "CHANGELOG.md"
  ]
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "redis", "~> 5.0"  # Standard Redis client
  spec.add_dependency "hiredis-client", "~> 0.22"     # Fast C-based Redis protocol parser
  spec.add_dependency "connection_pool", "~> 2.4"
  spec.add_dependency "activesupport", ">= 6.1", "< 9.0" # Required for Rails integration

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.4"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "standard", "~> 1.35.1"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "pry", "~> 0.14"

  spec.post_install_message = <<~MESSAGE
    Thanks for installing RedisService!

    To set up RedisService configuration, run:
      rails generate redis_service:install
  MESSAGE
end 