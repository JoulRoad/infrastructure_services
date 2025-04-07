# frozen_string_literal: true

RSpec.describe AerospikeService::Client do
  let(:default_namespace) { AerospikeService.configuration.default_namespace }

  describe AerospikeService::Client::BaseClient do
    let(:client) { AerospikeService::Client::BaseClient.new }

    it "uses default namespace" do
      expect(client.send(:current_namespace)).to eq(default_namespace)
    end

    # Add more client tests for individual operations
    # These should focus on how the client delegates to Aerospike
    # without actually connecting to a real server
  end

  describe AerospikeService::Client::NamespaceClient do
    let(:namespace) { "users" }
    let(:client) { AerospikeService::Client::NamespaceClient.new(namespace_name: namespace) }

    it "uses provided namespace" do
      expect(client.send(:current_namespace)).to eq(namespace)
    end

    it "has namespace_name accessor" do
      expect(client.namespace_name).to eq(namespace)
    end
  end

  describe AerospikeService::Client::ConnectionManager do
    let(:manager) { AerospikeService::Client::ConnectionManager.new(configuration: AerospikeService.configuration) }

    it "initializes without connections" do
      expect(manager.connections).to be_empty
    end

    # Connection tests are difficult to unit test without mocks
    # Focus on integration tests for actual connections
  end
end
