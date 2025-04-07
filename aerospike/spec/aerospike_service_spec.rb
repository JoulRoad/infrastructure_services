# frozen_string_literal: true

RSpec.describe AerospikeService do
  it "has a version number" do
    expect(AerospikeService::VERSION).not_to be nil
  end

  describe ".configuration" do
    it "returns a Configuration object" do
      expect(AerospikeService.configuration).to be_a(AerospikeService::Configuration::Config)
    end
  end

  describe ".configure" do
    it "allows configuring via a block" do
      AerospikeService.configure do |config|
        config.default_namespace = "custom"
      end

      expect(AerospikeService.configuration.default_namespace).to eq("custom")
    end
  end

  describe ".namespace" do
    it "returns a namespace client" do
      client = AerospikeService.namespace(name: "test")
      expect(client).to be_a(AerospikeService::Client::NamespaceClient)
      expect(client.namespace_name).to eq("test")
    end
  end

  describe "dynamic namespace access" do
    before do
      AerospikeService.configure do |config|
        config.namespaces = ["test", "custom"]
      end
    end

    it "allows accessing namespaces as methods" do
      expect(AerospikeService.test).to be_a(AerospikeService::Client::NamespaceClient)
      expect(AerospikeService.custom).to be_a(AerospikeService::Client::NamespaceClient)
      expect(AerospikeService.test.namespace_name).to eq("test")
    end

    it "raises NoMethodError for undefined namespaces" do
      expect { AerospikeService.undefined_namespace }.to raise_error(NoMethodError)
    end
  end
end
