# frozen_string_literal: true

require "yaml"
require "erb"

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

        apply_config(env_config: env_config, config: config)
        config
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
