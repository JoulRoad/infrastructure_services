RSpec.describe "Batch Read Operations" do
  let(:namespace) { AerospikeService.configuration.default_namespace }
  let(:key1) { "test-key1-#{Time.now.to_i}-#{rand(1000)}" }
  let(:key2) { "test-key2-#{Time.now.to_i}-#{rand(1000)}" }
  let(:missing_key) { "missing-key-#{Time.now.to_i}-#{rand(1000)}" }
  let(:setname) { "test" }

  let(:data1) { {"name" => "Alice", "active" => true} }
  let(:data2) { {"name" => "Bob", "active" => false} }

  before do
    AerospikeService.set(key: key1, value: {"name" => "Alice", "active" => "true"}, namespace: namespace, setname: setname)
    AerospikeService.set(key: key2, value: {"name" => "Bob", "active" => "false"}, namespace: namespace, setname: setname)
  end

  describe ".mget" do
    it "returns full records for multiple keys" do
      result = AerospikeService.mget(keys: [key1, key2], namespace: namespace, setname: setname)

      expect(result.size).to eq(2)
      expect(result[0]).to include("name" => "Alice", "active" => "true")
      expect(result[1]).to include("name" => "Bob", "active" => "false")
    end

    it "returns only specified bin when given a single bin" do
      result = AerospikeService.mget(keys: [key1, key2], bins: "name", namespace: namespace, setname: setname)
      expect(result).to eq(["Alice", "Bob"])
    end

    it "returns nil for a missing key" do
      result = AerospikeService.mget(keys: [key1, missing_key], bins: ["name", "active"], namespace: namespace, setname: setname)

      expect(result.size).to eq(2)
      expect(result[0]).to include("name" => "Alice", "active" => "true")
      expect(result[1]).to be_nil
    end

    it "returns an empty array when given an empty key list" do
      result = AerospikeService.mget(keys: [], namespace: namespace, setname: setname)
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