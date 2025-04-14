Gem::Specification.new do |spec|
    spec.name          = "app_services"
    spec.version       = "0.1.0"
    spec.authors       = ["V-Mart"]
    spec.email         = ["ujjwal@limeroad.com"]
    spec.summary       = "A gem for product, story,user etc models."
    spec.description   = "Service layer for managing entities using custom aerospike, redis, solr, and rest_api gems."
    spec.files         = Dir["lib/**/*","README.md", "LICENSE.txt", "CHANGELOG.md"]
    spec.bindir        = "bin"
    spec.require_paths = ["lib"]
    spec.homepage = "https://github.com/JoulRoad/infrastructure_services"
    spec.required_ruby_version = ">= 3.3.7"
    
    # Optional runtime dependencies
    spec.add_runtime_dependency "aerospike", "~> 0.1"  # Your custom gem
    spec.add_runtime_dependency "redis", "~> 0.1"      # Your custom gem
    spec.add_runtime_dependency "solr", "~> 0.1"       # Your custom gem
    spec.add_runtime_dependency "rest_api", "~> 0.1"   # Your custom gem
  
    spec.add_development_dependency "rails", "~> 8.0.2"  # For ActiveSupport in dev
    spec.add_development_dependency "rspec", "~> 3.0"  # For testing
  end