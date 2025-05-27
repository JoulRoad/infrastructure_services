# frozen_string_literal: true

require "yaml"
require "erb"
require "zk"
require "ipaddr"

module AerospikeService
  module Configuration
    module Loader
      module_function

      def load(file_path:, config:, fallback_path: nil)
        env = determine_environment

        zk_connected = false
        begin
          zk = ZK.new("127.0.0.1:2181", timeout: 2)
          zk_connected = zk.connected?
          zk.close
        rescue => e
          warn "Zookeeper connection failed: #{e.message}"
          zk_connected = false
        end

        use_zk_file = zk_connected && File.exist?(file_path)
        active_file = use_zk_file ? file_path : fallback_path

        raise ConfigError, "Configuration file not found: #{active_file}" unless active_file && File.exist?(active_file)

        puts "data loaded from: #{use_zk_file ? "zookeepr" : "yaml"} (#{active_file})"

        yaml_content = ERB.new(File.read(active_file)).result
        all_configs = YAML.safe_load(yaml_content)
        env_config = all_configs[env] || {}

        use_zookeeper = use_zk_file &&
          env_config["namespaces"].is_a?(Hash) &&
          env_config["namespaces"].values.any? { |v| v.is_a?(Hash) && v["zk_path"] }

        converted_env_config = use_zookeeper ? convertConfig(env_config) : env_config
        converted_env_config["config_source"] = use_zookeeper ? "zookeeper" : "yaml"

        apply_config(env_config: converted_env_config, config: config)
        config
      end

      def convertConfig(config)
        return config unless config["namespaces"].is_a?(Hash)

        converted = Marshal.load(Marshal.dump(config))
        converted["namespaces"] = config["namespaces"].keys

        converted["namespace_configs"] ||= {}

        zk = ZK.new("127.0.0.1:2181")

        config["namespaces"].each do |namespace, details|
          next unless details.is_a?(Hash) && details["zk_path"]
          zk_path = details["zk_path"]

          begin
            raw_data, _ = zk.get(zk_path)
            next if raw_data.nil? || raw_data.empty?

            if raw_data.strip.start_with?("[")
              begin
                seed_array = JSON.parse(raw_data)
                seed_string = seed_array.join(",")
              rescue JSON::ParserError => e
                warn "JSON parsing failed: #{e.message}"
                seed_string = raw_data
              end
            else
              seed_string = raw_data
            end

            seedlist = seed_string.split(",").map(&:strip).select do |host_entry|
              ip = host_entry.split(":").first
              valid_ip?(ip)
            end

            parsed_hosts = parse_hosts(hosts: seedlist)

            unless parsed_hosts.empty?
              converted["namespace_configs"][namespace] = {"hosts" => parsed_hosts}
            end
          rescue => e
            warn "Failed to fetch or parse seedlist from #{zk_path}: #{e.message}"
          end
        end

        zk&.close

        puts "converted is #{converted}"
        converted
      end

      def valid_ip?(ip)
        !!IPAddr.new(ip)
      rescue IPAddr::InvalidAddressError
        false
      end

      def determine_environment
        return "test" if ENV["RACK_ENV"] == "test" || ENV["RAILS_ENV"] == "test"

        if defined?(Rails)
          Rails.env.to_s
        else
          ENV["RACK_ENV"] || ENV["RAILS_ENV"] || "development"
        end
      end

      def apply_config(env_config:, config:)
        config.hosts = parse_hosts(hosts: env_config["hosts"]) if env_config["hosts"]
        config.default_namespace = env_config["default_namespace"] if env_config["default_namespace"]
        config.namespaces = env_config["namespaces"] if env_config["namespaces"]
        config.namespace_configs = env_config["namespace_configs"] || {}
        config.connect_timeout = env_config["connect_timeout"].to_f if env_config["connect_timeout"]
        config.timeout = env_config["timeout"].to_f if env_config["timeout"]
        config.max_retries = env_config["max_retries"].to_i if env_config["max_retries"]
        config.max_connections = env_config["max_connections"].to_i if env_config["max_connections"]
      end

      def parse_hosts(hosts:)
        case hosts
        when String
          [Config.new.parse_host(host_string: hosts)]
        when Array
          hosts.map do |host|
            host.is_a?(String) ? Config.new.parse_host(host_string: host) : host
          end
        else
          [{host: "127.0.0.1", port: 3000}]
        end
      end
    end
  end
end
