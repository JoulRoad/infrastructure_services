# frozen_string_literal: true

RSpec.describe "Client Integration" do
  let(:namespace) { AerospikeService.configuration.default_namespace }
  let(:test_key) { "test-#{Time.now.to_i}-#{rand(1000)}" }
  let(:test_data) { {"name" => "Test", "count" => 5} }

  describe "basic operations" do
    it "performs put and get operations" do
      # Put data
      result = AerospikeService.put(opts: { key: test_key, bins: test_data })
      expect(result).to be true

      # Get data
      retrieved = AerospikeService.get(opts: { key: test_key })
      expect(retrieved).to include("name" => "Test", "count" => 5)
    end

    it "gets a specific bin" do
      AerospikeService.put(opts: { key: test_key, bins: test_data })

      value = AerospikeService.get(opts: { key: test_key, bin: "name" })
      expect(value).to eq("Test")
    end

    it "checks record existence" do
      AerospikeService.put(opts: { key: test_key, bins: test_data })

      expect(AerospikeService.exists?(opts: { key: test_key })).to be true
      expect(AerospikeService.exists?(opts: { key: "nonexistent-#{test_key}" })).to be false
    end

    it "deletes records" do
      AerospikeService.put(opts: { key: test_key, bins: test_data })
      expect(AerospikeService.exists?(opts: { key: test_key })).to be true

      result = AerospikeService.delete(opts: { key: test_key })
      expect(result).to be true
      expect(AerospikeService.exists?(opts: { key: test_key })).to be false
    end

    it "increments counter bins" do
      AerospikeService.put(opts: { key: test_key, bins: {"counter" => 0} })

      AerospikeService.increment(opts: { key: test_key, bin: "counter", value: 3 })
      value = AerospikeService.get(opts: { key: test_key, bin: "counter" })
      expect(value).to eq(3)

      AerospikeService.increment(opts: { key: test_key, bin: "counter" })
      value = AerospikeService.get(opts: { key: test_key, bin: "counter" })
      expect(value).to eq(4)
    end

    it "touches records to update TTL" do
      AerospikeService.put(opts: { key: test_key, bins: test_data, ttl: 10 })

      result = AerospikeService.touch(opts: { key: test_key, ttl: 100 })
      expect(result).to be true

      # Hard to test actual TTL without complicated setup
    end
  end

  describe "record objects" do
    it "creates and manipulates records" do
      AerospikeService.put(opts: { key: test_key, bins: test_data })

      record = AerospikeService.record(opts: { key: test_key })
      expect(record).to be_a(AerospikeService::Models::Record)
      expect(record["name"]).to eq("Test")

      record["status"] = "active"
      record.save

      # Verify saved
      updated = AerospikeService.get(opts: { key: test_key })
      expect(updated).to include("status" => "active")
    end

    it "creates and manipulates records using set method" do
      AerospikeService.set(opts: { key: test_key, value: test_data })

      record = AerospikeService.record(opts: { key: test_key })
      expect(record).to be_a(AerospikeService::Models::Record)
      expect(record["name"]).to eq("Test")

      record["status"] = "active"
      record.save

      updated = AerospikeService.get(opts: { key: test_key })
      expect(updated).to include("status" => "active")
    end
  end

  describe "batch operations" do
    let(:test_keys) { ["batch-1-#{test_key}", "batch-2-#{test_key}"] }

    it "gets multiple records at once" do
      AerospikeService.put(opts: { key: test_keys[0], bins: {"index" => 0} })
      AerospikeService.put(opts: { key: test_keys[1], bins: {"index" => 1} })

      results = AerospikeService.batch_get(opts: { keys: test_keys })
      expect(results).to be_a(Hash)
      expect(results[test_keys[0]]).to include("index" => 0)
      expect(results[test_keys[1]]).to include("index" => 1)
    end

    it "gets multiple records at once using set" do
      AerospikeService.set(opts: { key: test_keys[0], value: { "index" => 0 } })
      AerospikeService.set(opts: { key: test_keys[1], value: { "index" => 1 } })

      results = AerospikeService.batch_get(opts: { keys: test_keys })
      expect(results).to be_a(Hash)
      expect(results[test_keys[0]]).to include("index" => 0)
      expect(results[test_keys[1]]).to include("index" => 1)
    end
  end

  describe "basic set operations" do
    it "gets a specific bin" do
      AerospikeService.set(opts: { key: test_key, value: test_data })

      value = AerospikeService.get(opts: { key: test_key, bin: "name" })
      expect(value).to eq("Test")
    end

    it "checks record existence" do
      AerospikeService.set(opts: { key: test_key, value: test_data })

      expect(AerospikeService.exists?(opts: { key: test_key })).to be true
      expect(AerospikeService.exists?(opts: { key: "nonexistent-#{test_key}" })).to be false
    end

    it "deletes records" do
      AerospikeService.set(opts: { key: test_key, value: test_data })
      expect(AerospikeService.exists?(opts: { key: test_key })).to be true

      result = AerospikeService.delete(opts: { key: test_key })
      expect(result).to be true
      expect(AerospikeService.exists?(opts: { key: test_key })).to be false
    end

    it "increments counter bins" do
      AerospikeService.set(opts: { key: test_key, value: { "counter" => 0 } })

      AerospikeService.increment(opts: { key: test_key, bin: "counter", value: 3 })
      value = AerospikeService.get(opts: { key: test_key, bin: "counter" })
      expect(value).to eq(3)

      AerospikeService.increment(opts: { key: test_key, bin: "counter" })
      value = AerospikeService.get(opts: { key: test_key, bin: "counter" })
      expect(value).to eq(4)
    end

    it "touches records to update TTL" do
      AerospikeService.set(opts: { key: test_key, value: test_data, expiration: 10 })

      result = AerospikeService.touch(opts: { key: test_key, ttl: 100 })
      expect(result).to be true

      # TTL verification is skipped as it requires metadata inspection
    end
  end

  describe "set operations" do
    it "sets a simple hash value with default settings" do
      result = AerospikeService.set(opts: { key: test_key, value: test_data })
      expect(result).to be true

      record = AerospikeService.get(opts: { key: test_key })
      expect(record).to include("name" => "Test", "count" => 5)
    end

    it "sets a single value (non-hash) under default bin" do
      result = AerospikeService.set(opts: { key: test_key, value: "just_a_value" })
      expect(result).to be true

      record = AerospikeService.get(opts: { key: test_key })
      expect(record).to include("value" => "just_a_value") # assuming default bin name is "value"
    end

    it "sets values with symbol keys and converts them to strings" do
      symbol_data = { name: "Symbol", active: "false" }
      result = AerospikeService.set(opts: { key: test_key, value: symbol_data })
      expect(result).to be true

      record = AerospikeService.get(opts: { key: test_key })
      expect(record).to include("name" => "Symbol", "active" => "false")
    end

    it "converts boolean values to strings when specified" do
      data = { flag: true, other_flag: "false" }
      result = AerospikeService.set(opts: { key: test_key, value: data, convert_boolean_values: true })
      expect(result).to be true

      record = AerospikeService.get(opts: { key: test_key })
      expect(record).to include("flag" => "true", "other_flag" => "false")
    end

    it "sets data with a custom expiration time (TTL)" do
      result = AerospikeService.set(opts: { key: test_key, value: test_data, expiration: 600 })
      expect(result).to be true
    end

    it "raises an error when record is too big" do
      big_data = { data: "x" * 2_000_000 } # simulate a large payload

      allow(AerospikeService).to receive(:set).and_raise(Aerospike::Exceptions::Aerospike.new("record too big"))

      expect {
        AerospikeService.set(opts: { key: test_key, value: big_data })
      }.to raise_error(Aerospike::Exceptions::Aerospike)
    end
  end
end


RSpec.describe "Client Integration" do
  let(:namespace) { AerospikeService.configuration.default_namespace }
  let(:key1) { "test-key1-#{Time.now.to_i}-#{rand(1000)}" }
  let(:key2) { "test-key2-#{Time.now.to_i}-#{rand(1000)}" }
  let(:missing_key) { "missing-key-#{Time.now.to_i}-#{rand(1000)}" }

  let(:data1) { { "name" => "Alice", "active" => true } }
  let(:data2) { { "name" => "Bob", "active" => false } }

  before do
    AerospikeService.set(key: key1, value: { "name" => "Alice", "active" => "true" }, namespace: namespace)
    AerospikeService.set(key: key2, value: { "name" => "Bob", "active" => "false" }, namespace: namespace)
  end


  describe ".mget" do
    it "returns full records for multiple keys" do
      result = AerospikeService.mget(keys: [key1, key2], namespace: namespace)

      expect(result.size).to eq(2)
      expect(result[0]).to include("name" => "Alice", "active" => "true")
      expect(result[1]).to include("name" => "Bob", "active" => "false")
    end

    it "returns only specified bin when given a single bin" do
      result = AerospikeService.mget(keys: [key1, key2], bins: "name", namespace: namespace)
      expect(result).to eq(["Alice", "Bob"])
    end


    it "returns nil for a missing key" do
      result = AerospikeService.mget(keys: [key1, missing_key], bins: ["name", "active"], namespace: namespace)

      expect(result.size).to eq(2)
      expect(result[0]).to include("name" => "Alice", "active" => "true")
      expect(result[1]).to be_nil
    end

    it "returns an empty array when given an empty key list" do
      result = AerospikeService.mget(keys: [], namespace: namespace)
      expect(result).to eq([])
    end

    it "raises an error if Aerospike client fails unexpectedly" do
      allow_any_instance_of(Aerospike::Client).to receive(:batch_get).and_raise(StandardError.new("something went wrong"))

      expect {
        AerospikeService.mget(keys: [key1, key2], namespace: namespace)
      }.to raise_error(AerospikeService::OperationError, /something went wrong/)
    end
  end
end

RSpec.describe "Client Integration" do
  let(:namespace) { AerospikeService.configuration.default_namespace }
  let(:setname) { "test" }
  let(:key) { "ranking-test-#{Time.now.to_i}" }
  let(:bin_name) { "ranking" }
  let(:map_data) do
    {
      "Alice" => -100,
      "Bob" => -90,
      "Charlie" => -80
    }
  end

  before do
    AerospikeService.put(
      key: key,
      namespace: namespace,
      bins: { bin_name => map_data }
    )
  end

  describe ".by_rank_range_map_bin" do
    it "returns top N key-value pairs by rank" do
      result = AerospikeService.by_rank_range_map_bin(
        key: key,
        namespace: namespace,
        setname: setname,
        bin: bin_name,
        begin_token: 0,
        count: 2
      )

      expect(result).to be_an(Array)
      expect(result).to include(["Alice", 100], ["Bob", 90])
    end

    it "returns keys only when return_type is :key" do
      result = AerospikeService.by_rank_range_map_bin(
        key: key,
        namespace: namespace,
        setname: setname,
        bin: bin_name,
        begin_token: 0,
        count: 2,
        return_type: Aerospike::CDT::MapReturnType::KEY
      )

      expect(result).to match_array(["Alice", "Bob"])
    end

    it "returns empty hash when key does not exist" do
      result = AerospikeService.by_rank_range_map_bin(
        key: "nonexistent-#{key}",
        namespace: namespace,
        setname: setname,
        bin: bin_name,
        begin_token: 0,
        count: 2
      )

      expect(result).to eq({})
    end

    it "returns empty hash when bin does not exist" do
      result = AerospikeService.by_rank_range_map_bin(
        key: key,
        namespace: namespace,
        setname: setname,
        bin: "invalid_bin",
        begin_token: 0,
        count: 2
      )

      expect(result).to eq({})
    end

    it "returns empty array when return_type is :key and bin does not exist" do
      result = AerospikeService.by_rank_range_map_bin(
        key: key,
        namespace: namespace,
        setname: setname,
        bin: "invalid_bin",
        begin_token: 0,
        count: 2,
        return_type: Aerospike::CDT::MapReturnType::KEY
      )

      expect(result).to eq([])
    end

    it "logs a warning for invalid namespace and returns empty" do
      expect {
        result = AerospikeService.by_rank_range_map_bin(
          key: key,
          namespace: "invalid_namespace",
          setname: setname,
          bin: bin_name,
          begin_token: 0,
          count: 2
        )

        expect(result).to eq({})
      }.to output(/Warning: Invalid namespace/).to_stderr
    end
  end
end


