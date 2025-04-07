# frozen_string_literal: true

namespace :aerospike_service do
  desc "Verify connection to Aerospike"
  task verify_connection: :environment do
    info = AerospikeService.client.connection_for_namespace(
      AerospikeService.configuration.default_namespace
    ).info

    puts "Connected to Aerospike cluster"
    puts "Cluster name: #{info.cluster_name}"
    puts "Namespaces: #{info.namespaces.join(", ")}"
    puts "Node count: #{info.node_count}"
  rescue => e
    puts "Failed to connect to Aerospike: #{e.message}"
    exit 1
  end

  desc "Clear all data in a namespace"
  task :clear_namespace, [:namespace] => :environment do |t, args|
    namespace = args[:namespace] || AerospikeService.configuration.default_namespace

    if ENV["CONFIRM"] != "true"
      puts "DANGER: This will delete all data in namespace '#{namespace}'"
      puts "To confirm, run with CONFIRM=true"
      exit 1
    end

    begin
      # Use scan and delete operation
      # Just remove the assignment or use it
      AerospikeService.client.connection_for_namespace(namespace)

      puts "Clearing namespace '#{namespace}'..."

      # Implementation would depend on Aerospike client API
      # This is a placeholder for the actual implementation
      puts "Not implemented yet. Please use Aerospike tools to truncate namespace."
    rescue => e
      puts "Failed to clear namespace: #{e.message}"
      exit 1
    end
  end
end
