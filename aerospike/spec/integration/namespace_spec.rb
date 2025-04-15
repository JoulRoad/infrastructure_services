# frozen_string_literal: true

RSpec.describe "Namespace Integration" do
  let(:test_key) { "ns-test-#{Time.now.to_i}-#{rand(1000)}" }
  let(:namespaces) { AerospikeService.configuration.namespaces }
  let(:namespace1) { namespaces[0] }
  let(:namespace2) { namespaces[1] || namespaces[0] }

  before do
    # Skip tests if not enough namespaces configured
    skip "This test requires at least one namespace configured" if namespaces.empty?
  end

  describe "namespace clients" do
    it "accesses different namespaces via direct method" do
      client1 = AerospikeService.namespace(name: namespace1)
      expect(client1).to be_a(AerospikeService::Client::NamespaceClient)
      expect(client1.namespace_name).to eq(namespace1)
    end

    it "accesses namespaces as methods" do
      # Only run this test if namespace name is a valid method name
      if namespace1 =~ /^[a-z_][a-zA-Z0-9_]*$/ && namespace1 != "test"
        expect {
          client = AerospikeService.public_send(namespace1.to_sym)
          expect(client).to be_a(AerospikeService::Client::NamespaceClient)
          expect(client.namespace_name).to eq(namespace1)
        }.not_to raise_error
      end
    end
  end

  describe "namespace isolation" do
    it "keeps data separate between namespaces" do
      # Skip if only one namespace
      skip "This test requires multiple namespaces" if namespaces.size < 2

      client1 = AerospikeService.namespace(name: namespace1)
      client2 = AerospikeService.namespace(name: namespace2)

      # Put data in one namespace
      client1.put(key: test_key, bins: {"value" => "namespace1-data"})

      # Should only be available in that namespace
      expect(client1.get(key: test_key)).to include("value" => "namespace1-data")
      expect(client2.get(key: test_key)).to be_nil
    end
  end

  describe "namespace operations" do
    it "supports all operations with namespaces" do
      client = AerospikeService.namespace(name: namespace1)

      client.put(key: test_key, bins: {"count" => 0})
      expect(client.get(key: test_key)).to include("count" => 0)

      client.delete(key: test_key)
      expect(client.exists?(key: test_key)).to be false
    end

    it "supports mget with multiple keys" do
      client = AerospikeService.namespace(name: namespace1)

      keys = ["#{test_key}-1", "#{test_key}-2", "#{test_key}-3"]
      values = [
        {"value" => "one"},
        {"value" => "two"},
        {"value" => "three"}
      ]

      keys.each_with_index do |key, idx|
        client.set(key: key, value: values[idx])
      end

      result = client.mget(keys: keys)

      expect(result.size).to eq(3)
      expect(result[0]).to include("value" => "one")
      expect(result[1]).to include("value" => "two")
      expect(result[2]).to include("value" => "three")

      keys.each { |key| client.delete(key: key) }
    end
  end

  describe "custom client methods in namespace" do
    let(:client) { AerospikeService.namespace(name: namespace1) }

    it "sets and gets values using #set and #get" do
      key = "#{test_key}-set-get"
      value = {"score" => 42}

      client.set(key: key, value: value)
      result = client.get(key: key)

      expect(result).to include("score" => 42)
    end

    it "handles by_rank_range_map_bin correctly" do
      key = "#{test_key}-rank-range"
      map_bin = "rankings"

      client.set(
        key: key,
        value: {map_bin => {"a" => 1, "b" => 2, "c" => 3}}
      )

      result = client.by_rank_range_map_bin(
        key: key,
        bin: map_bin,
        begin_token: 0,
        count: 2
      )
      expect(result).to include(["a", -1], ["b", -2])
    end
  end
end
