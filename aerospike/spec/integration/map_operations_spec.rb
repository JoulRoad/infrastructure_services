RSpec.describe "Map Rank Range Integration" do
  let(:namespace) { AerospikeService.configuration.default_namespace }
  let(:setname) { "test" }
  let(:key) { "ranking-test-#{Time.now.to_i}" }
  let(:bin_name) { "ranking" }
  let(:expiration) { 7 * 24 * 60 * 60 }
  let(:map_data) do
    {
      "Alice" => -100,
      "Bob" => -90,
      "Charlie" => -80
    }
  end

  before do
    AerospikeService.set(
      key: key,
      namespace: namespace,
      setname: setname,
      value: {bin_name => map_data},
      expiration: expiration
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
        count: 2,
        expiration: expiration,
        return_type: Aerospike::CDT::MapReturnType::KEY_VALUE
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
        expiration: expiration,
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
        count: 2,
        expiration: expiration
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
        count: 2,
        expiration: expiration
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
        expiration: expiration,
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
          count: 2,
          expiration: expiration
        )

        expect(result).to eq({})
      }.to output(/Warning: Invalid namespace/).to_stderr
    end
  end
end
