# frozen_string_literal: true

require "yaml"
require "erb"
require "zk"
require "ipaddr"

module AerospikeService
  module Configuration
    module Loader
      module_function

      def load(file_path:, config:)
        raise ConfigError, "Configuration file not found: #{file_path}" unless File.exist?(file_path)

        yaml_content = ERB.new(File.read(file_path)).result
        all_configs = YAML.safe_load(yaml_content)

        env = determine_environment
        env_config = all_configs[env] || {}

        converted_env_config = convertConfig(env_config)
        apply_config(env_config: converted_env_config, config: config)

        config
      end

      def convertConfig(config)
        return config unless config["namespaces"].is_a?(Hash)

        converted = Marshal.load(Marshal.dump(config))
        converted["namespace_configs"] ||= {}

        zk = ZK.new("127.0.0.1:2181")
        converted["namespaces"].each do |namespace, details|
          next unless details.is_a?(Hash) && details["zk_path"]
          zk_path = details["zk_path"]

          begin
            raw_data, _ = zk.get(zk_path)

            next if raw_data.nil? || raw_data.empty?

            # NEW: Handle stringified JSON array from ZK
            if raw_data.strip.start_with?("[")
              begin
                seed_array = JSON.parse(raw_data)
                seed_string = seed_array.join(",") # convert back to "host:port,host:port" string
              rescue JSON::ParserError => e
                warn "JSON parsing failed: #{e.message}"
                seed_string = raw_data
              end
            else
              seed_string = raw_data
            end

            seedlist = seed_string.split(",").map(&:strip).select do |host_entry|
              ip = host_entry.split(":").first
              valid = valid_ip?(ip)
              valid
            end

            parsed_hosts = parse_hosts(hosts: seedlist)
            puts "seedlist data #{parsed_hosts}"

            converted["namespace_configs"][namespace] = {"hosts" => parsed_hosts} unless parsed_hosts.empty?
          rescue => e
            warn "Failed to fetch or parse seedlist from #{zk_path}: #{e.message}"
          end
        end
        zk&.close

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
