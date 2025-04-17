# frozen_string_literal: true

RSpec.describe "Client Integration" do
  let(:namespace) { AerospikeService.configuration.default_namespace }
  let(:setname) { "test" }
  let(:test_key) { "test-#{Time.now.to_i}-#{rand(1000)}" }
  let(:test_data) { {"name" => "Test", "count" => 5} }

  describe "basic operations" do
    it "performs set and get operations" do
      result = AerospikeService.set(key: test_key, setname: setname, value: test_data)
      expect(result).to be true

      retrieved = AerospikeService.get(key: test_key, setname: setname, bins: ["name", "count"])
      expect(retrieved).to include("name" => "Test", "count" => 5)
    end

    it "gets a specific bin" do
      AerospikeService.set(key: test_key, setname: setname, value: test_data)

      value = AerospikeService.get(key: test_key, setname: setname, bins: ["name"])
      expect(value["name"]).to eq("Test")
    end

    it "checks record existence" do
      AerospikeService.set(key: test_key, setname: setname, value: test_data)

      expect(AerospikeService.exists?(key: test_key)).to be true
      expect(AerospikeService.exists?(key: "nonexistent-#{test_key}")).to be false
    end

    it "deletes records" do
      AerospikeService.set(key: test_key, setname: setname, value: test_data)
      expect(AerospikeService.exists?(key: test_key)).to be true

      result = AerospikeService.delete(key: test_key, setname: setname)
      expect(result).to be true
      expect(AerospikeService.exists?(key: test_key, setname: setname)).to be false
    end

    it "increments counter bins" do
      AerospikeService.set(key: test_key, setname: setname, value: {"counter" => 0})

      AerospikeService.increment(key: test_key, setname: setname, bin: "counter", incr_by: 3)
      value = AerospikeService.get(key: test_key, setname: setname, bins: ["counter"])
      expect(value["counter"]).to eq(3)

      AerospikeService.increment(key: test_key, setname: setname, bin: "counter", incr_by: 1)
      value = AerospikeService.get(key: test_key, setname: setname, bins: ["counter"])
      expect(value["counter"]).to eq(4)
    end

    it "touches records to update TTL" do
      AerospikeService.set(key: test_key, setname: setname, value: test_data, expiration: 10)

      result = AerospikeService.touch(key: test_key, setname: setname, expiration: 100)
      expect(result).to be true
    end
  end

  describe "record objects" do
    it "creates and manipulates records" do
      AerospikeService.set(key: test_key, setname: setname, value: test_data)

      record = AerospikeService.record(key: test_key, setname: setname)
      expect(record).to be_a(AerospikeService::Models::Record)
      expect(record["name"]).to eq("Test")

      record["status"] = "active"
      record.save

      updated = AerospikeService.get(key: test_key, setname: setname, bins: ["status"])
      expect(updated).to include("status" => "active")
    end
  end

  describe "batch operations" do
    let(:test_keys) { ["batch-1-#{test_key}", "batch-2-#{test_key}"] }

    it "gets multiple records at once" do
      AerospikeService.set(key: test_keys[0], setname: setname, value: {"index" => 0})
      AerospikeService.set(key: test_keys[1], setname: setname, value: {"index" => 1})

      results = AerospikeService.batch_get(keys: test_keys, setname: setname)
      expect(results).to be_a(Hash)
      expect(results[test_keys[0]]).to include("index" => 0)
      expect(results[test_keys[1]]).to include("index" => 1)
    end
  end

  describe "set operations" do
    it "sets a simple hash value with default settings" do
      result = AerospikeService.set(key: test_key, value: test_data, setname: setname)
      expect(result).to be true

      record = AerospikeService.get(key: test_key, setname: setname, bins: ["name", "count"])
      expect(record).to include("name" => "Test", "count" => 5)
    end

    it "sets a single value (non-hash) under default bin" do
      result = AerospikeService.set(key: test_key, value: "just_a_value", setname: setname)
      expect(result).to be true

      record = AerospikeService.get(key: test_key, setname: setname, bins: ["value"])
      expect(record).to include("value" => "just_a_value")
    end

    it "sets values with symbol keys and converts them to strings" do
      symbol_data = {name: "Symbol", active: "false"}
      result = AerospikeService.set(key: test_key, value: symbol_data, setname: setname)
      expect(result).to be true

      record = AerospikeService.get(key: test_key, setname: setname, bins: ["name", "active"])
      expect(record).to include("name" => "Symbol", "active" => "false")
    end

    it "converts boolean values to strings when specified" do
      data = {flag: true, other_flag: "false"}
      result = AerospikeService.set(key: test_key, value: data, convert_boolean_values: true, setname: setname)
      expect(result).to be true

      record = AerospikeService.get(key: test_key, setname: setname, bins: ["flag", "other_flag"])
      expect(record).to include("flag" => "true", "other_flag" => "false")
    end

    it "sets data with a custom expiration time (TTL)" do
      result = AerospikeService.set(key: test_key, value: test_data, expiration: 600, setname: setname)
      expect(result).to be true
    end

    it "raises an error when record is too big" do
      big_data = {data: "x" * 2_000_000}

      allow(AerospikeService).to receive(:set).and_raise(Aerospike::Exceptions::Aerospike.new("record too big"))

      expect {
        AerospikeService.set(key: test_key, value: big_data, setname: setname)
      }.to raise_error(Aerospike::Exceptions::Aerospike)
    end
  end
end




