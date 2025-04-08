# frozen_string_literal: true

RSpec.describe "Client Integration" do
  let(:namespace) { AerospikeService.configuration.default_namespace }
  let(:test_key) { "test-#{Time.now.to_i}-#{rand(1000)}" }
  let(:test_data) { {"name" => "Test", "count" => 5} }

  describe "basic operations" do
    it "performs put and get operations" do
      # Put data
      result = AerospikeService.put(key: test_key, bins: test_data)
      expect(result).to be true

      # Get data
      retrieved = AerospikeService.get(key: test_key)
      expect(retrieved).to include("name" => "Test", "count" => 5)
    end

    it "gets a specific bin" do
      AerospikeService.put(key: test_key, bins: test_data)

      value = AerospikeService.get(key: test_key, bin: "name")
      expect(value).to eq("Test")
    end

    it "checks record existence" do
      AerospikeService.put(key: test_key, bins: test_data)

      expect(AerospikeService.exists?(key: test_key)).to be true
      expect(AerospikeService.exists?(key: "nonexistent-#{test_key}")).to be false
    end

    it "deletes records" do
      AerospikeService.put(key: test_key, bins: test_data)
      expect(AerospikeService.exists?(key: test_key)).to be true

      result = AerospikeService.delete(key: test_key)
      expect(result).to be true
      expect(AerospikeService.exists?(key: test_key)).to be false
    end

    it "increments counter bins" do
      AerospikeService.put(key: test_key, bins: {"counter" => 0})

      AerospikeService.increment(key: test_key, bin: "counter", value: 3)
      value = AerospikeService.get(key: test_key, bin: "counter")
      expect(value).to eq(3)

      AerospikeService.increment(key: test_key, bin: "counter")
      value = AerospikeService.get(key: test_key, bin: "counter")
      expect(value).to eq(4)
    end

    it "touches records to update TTL" do
      AerospikeService.put(key: test_key, bins: test_data, ttl: 10)

      result = AerospikeService.touch(key: test_key, ttl: 100)
      expect(result).to be true

      # Hard to test actual TTL without complicated setup
    end
  end

  describe "record objects" do
    it "creates and manipulates records" do
      AerospikeService.put(key: test_key, bins: test_data)

      record = AerospikeService.record(key: test_key)
      expect(record).to be_a(AerospikeService::Models::Record)
      expect(record["name"]).to eq("Test")

      record["status"] = "active"
      record.save

      # Verify saved
      updated = AerospikeService.get(key: test_key)
      expect(updated).to include("status" => "active")
    end
  end

  describe "batch operations" do
    let(:test_keys) { ["batch-1-#{test_key}", "batch-2-#{test_key}"] }

    it "gets multiple records at once" do
      AerospikeService.put(key: test_keys[0], bins: {"index" => 0})
      AerospikeService.put(key: test_keys[1], bins: {"index" => 1})

      results = AerospikeService.batch_get(keys: test_keys)
      expect(results).to be_a(Hash)
      expect(results[test_keys[0]]).to include("index" => 0)
      expect(results[test_keys[1]]).to include("index" => 1)
    end
  end
end
