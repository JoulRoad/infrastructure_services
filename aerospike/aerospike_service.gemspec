# frozen_string_literal: true

require_relative "lib/aerospike_service/version"

Gem::Specification.new do |spec|
  spec.name = "aerospike_service"
  spec.version = AerospikeService::VERSION
  spec.authors = ["V-Mart"]
  spec.email = ["kumar.vaishnav@limeroad.com"]
  spec.license = "MIT"

  spec.summary = "Aerospike integration for Rails applications"
  spec.description = "A service-oriented adapter for Aerospike database with Rails integration, optimized for high performance and reliability"
  spec.homepage = "https://github.com/your-org/infrastructure_services"
  spec.required_ruby_version = ">= 3.3.7"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "#{spec.homepage}/tree/main/aerospike",
    "changelog_uri" => "#{spec.homepage}/blob/main/aerospike/CHANGELOG.md",
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
  spec.add_dependency "aerospike", "~> 2.7.0"  # Aerospike Ruby client
  spec.add_dependency "connection_pool", "~> 2.4"  # For connection pooling
  spec.add_dependency "activemodel", ">= 6.1", "< 9.0"  # For validation capabilities
  spec.add_dependency "activesupport", ">= 6.1", "< 9.0"  # For core extensions

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.4"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "simplecov", "~> 0.22"
  # spec.add_development_dependency "rubocop", "~> 1.50"
  # spec.add_development_dependency "rubocop-performance", "~> 1.18"
  # spec.add_development_dependency "rubocop-rspec", "~> 2.22"
  spec.add_development_dependency "standard", "~> 1.35.1"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "pry", "~> 0.14"

  spec.post_install_message = <<~MESSAGE
    Thanks for installing AerospikeService!

    To set up local bundler configuration for this project, run:
      rails generate aerospike_service:bundle_config

    To set up AerospikeService configuration, run:
      rails generate aerospike_service:install
  MESSAGE
end
