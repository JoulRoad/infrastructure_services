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
      client1 = AerospikeService.namespace(name: namespace1)
      client2 = AerospikeService.namespace(name: namespace2)

      client1.put(key: test_key, bins: {"value" => "namespace1-data"})

      expect(client1.get(key: test_key)).to include("value" => "namespace1-data")
      expect(client2.get(key: test_key)).to be_nil
    end
  end

  describe "namespace operations" do
    it "supports all operations with namespaces" do
      client = AerospikeService.namespace(name: namespace1)

      # Put
      client.put(key: test_key, bins: {"count" => 0})
      expect(client.get(key: test_key)).to include("count" => 0)

      # Delete
      client.delete(key: test_key)
      expect(client.exists?(key: test_key)).to be false
    end
  end
end
