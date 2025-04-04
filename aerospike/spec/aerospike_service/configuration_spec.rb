# frozen_string_literal: true

require "spec_helper"

RSpec.describe AerospikeService::Configuration do
  let(:config) { described_class.new }

  it "initializes with default values" do
    expect(config.hosts).to eq([{host: "127.0.0.1", port: 3000}])
    expect(config.default_namespace).to eq("test")
  end

  it "allows configuration via setters" do
    config.hosts = [{host: "aerospike.example.com", port: 4000}]
    config.default_namespace = "custom"

    expect(config.hosts).to eq([{host: "aerospike.example.com", port: 4000}])
    expect(config.default_namespace).to eq("custom")
  end
end
