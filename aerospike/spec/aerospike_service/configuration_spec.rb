# frozen_string_literal: true

RSpec.describe AerospikeService::Configuration do
  describe AerospikeService::Configuration::Config do
    let(:config) { AerospikeService::Configuration::Config.new }

    it "has default values" do
      expect(config.hosts).to be_an(Array)
      expect(config.default_namespace).to eq("test")
      expect(config.namespaces).to include("test")
    end

    describe "#hosts_for" do
      it "returns default hosts when no namespace config exists" do
        config.hosts = [{host: "127.0.0.1", port: 3000}]
        expect(config.hosts_for(namespace: "test")).to eq([{host: "127.0.0.1", port: 3000}])
      end

      it "returns namespace-specific hosts when configured" do
        config.hosts = [{host: "127.0.0.1", port: 3000}]
        config.namespace_configs = {
          "users" => {"hosts" => [{host: "users-host", port: 3001}]}
        }

        expect(config.hosts_for(namespace: "users")).to eq([{host: "users-host", port: 3001}])
        expect(config.hosts_for(namespace: "test")).to eq([{host: "127.0.0.1", port: 3000}])
      end
    end
  end

  describe AerospikeService::Configuration::Loader do
    let(:loader) { AerospikeService::Configuration::Loader }
    let(:config) { AerospikeService::Configuration::Config.new }
    let(:config_file) { File.join(File.dirname(__FILE__), "..", "config", "aerospike_service.yml") }
    let(:fallback_file) { File.join(File.dirname(__FILE__), "..", "config", "aerospike_switch.yml") }

    it "loads configuration from YAML file" do
      if File.exist?(config_file)
        loader.load(file_path: config_file, fallback_path: fallback_file, config: config)

        expect(config.hosts).to be_an(Array)
        expect(config.namespaces).to be_an(Array)
        expect(config.namespaces.size).to be > 0
      end
    end

    it "raises error when file not found" do
      expect {
        loader.load(file_path: "nonexistent.yml", fallback_path: "nonexistent_fallback.yml", config: config)
      }.to raise_error(AerospikeService::ConfigError)
    end
  end
end
