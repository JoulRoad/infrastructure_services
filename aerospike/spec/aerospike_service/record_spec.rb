# frozen_string_literal: true

RSpec.describe AerospikeService::Models::Record do
  let(:key) { "test-record" }
  let(:bins) { {"name" => "Test", "count" => 5} }
  let(:namespace) { "test" }
  let(:record) { AerospikeService::Models::Record.new(key: key, bins: bins, namespace: namespace) }

  it "initializes with key, bins and namespace" do
    expect(record.key).to eq(key)
    expect(record.bins).to eq(bins)
    expect(record.namespace).to eq(namespace)
  end

  describe "#[]" do
    it "accesses bin by name" do
      expect(record["name"]).to eq("Test")
    end

    it "accepts symbols as bin names" do
      expect(record[:name]).to eq("Test")
    end

    it "returns nil for non-existent bins" do
      expect(record["nonexistent"]).to be_nil
    end
  end

  describe "#[]=" do
    it "sets bin value" do
      record["status"] = "active"
      expect(record.bins["status"]).to eq("active")
    end

    it "accepts symbols as bin names" do
      record[:status] = "active"
      expect(record.bins["status"]).to eq("active")
    end
  end

  # Additional tests for save, delete, touch, increment, refresh
  # should be implemented in integration tests
end
