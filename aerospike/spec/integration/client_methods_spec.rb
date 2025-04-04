# frozen_string_literal: true

require "spec_helper"

# Skip if Aerospike is not available
if ENV["RUN_INTEGRATION"] || system("nc -z localhost 3000")
  RSpec.describe "Client Methods" do
    # Use random keys to avoid test collisions
    let(:test_key) { "test:#{Time.now.to_i}:#{rand(1000)}" }
    let(:test_keys) { [1, 2, 3].map { |i| "#{test_key}:#{i}" } }

    # Clean up after tests
    after do
      # Delete main test key
      begin
        AerospikeService.delete(test_key)
      rescue
        nil
      end

      # Delete batch test keys
      test_keys.each do |key|
        AerospikeService.delete(key)
      rescue
        nil
      end
    end

    it "tests #put and #get" do
      # Basic put/get
      AerospikeService.put(test_key, {"name" => "Test User", "age" => 30})
      result = AerospikeService.get(test_key)
      expect(result).to include("name" => "Test User", "age" => 30)

      # Get specific bin
      bin_result = AerospikeService.get(test_key, "name")
      expect(bin_result).to include("name" => "Test User")
      expect(bin_result).not_to include("age")
    end

    it "tests #exists?" do
      # Non-existent key
      expect(AerospikeService.exists?("nonexistent:#{rand(10000)}")).to be false

      # Existing key
      AerospikeService.put(test_key, {"value" => "exists"})
      expect(AerospikeService.exists?(test_key)).to be true
    end

    it "tests #delete" do
      # Create and verify record exists
      AerospikeService.put(test_key, {"value" => "delete me"})
      expect(AerospikeService.exists?(test_key)).to be true

      # Delete and verify it's gone
      expect(AerospikeService.delete(test_key)).to be true
      expect(AerospikeService.exists?(test_key)).to be false
    end

    it "tests #touch" do
      # Create record
      AerospikeService.put(test_key, {"value" => "touch test"})

      # Touch existing record
      expect(AerospikeService.touch(test_key)).to be true
    end

    it "tests #increment" do
      # Increment non-existent record (creates it)
      AerospikeService.increment(test_key, "counter")
      expect(AerospikeService.get(test_key)).to include("counter" => 1)

      # Increment existing counter
      AerospikeService.increment(test_key, "counter")
      expect(AerospikeService.get(test_key)).to include("counter" => 2)

      # Increment with custom value
      AerospikeService.increment(test_key, "counter", 5)
      expect(AerospikeService.get(test_key)).to include("counter" => 7)
    end

    it "tests #batch_get" do
      # Create test records
      test_keys.each_with_index do |key, i|
        AerospikeService.put(key, {"index" => i, "common" => "batch"})
      end

      # Get all records
      results = AerospikeService.batch_get(test_keys)
      expect(results.keys.sort).to eq(test_keys.sort)
      test_keys.each_with_index do |key, i|
        expect(results[key]).to include("index" => i)
      end
    end
  end
else
  puts "Skipping integration tests (Aerospike not available)"
end
