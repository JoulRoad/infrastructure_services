require_relative 'base_config'
require 'yaml'
require 'zk'
require 'json'
require "ipaddr"
require "erb"

# AerospikeService.load_configuration(file_path: config_file) to be changed acc to switch condution

module Config
  class ZookeeperConfig < BaseConfig

    def should_convert?
      config = YAML.load_file(config_file)
      config.key?("namespaces") && config["namespaces"].is_a?(Hash)
    rescue Errno::ENOENT, Psych::SyntaxError
      false
    end

    def convert_config
      config = YAML.load_file(config_file)
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

          seedlist = seed_string.split(",").map(&:strip).select { |host| valid_ip?(host.split(":").first) }
          parsed_hosts = parse_hosts(hosts: seedlist)

          converted["namespace_configs"][namespace] = { "hosts" => parsed_hosts } unless parsed_hosts.empty?
        rescue => e
          warn "Failed to parse seedlist for #{namespace}: #{e.message}"
        end
      end

      zk.close
      converted
    end

    private

    def valid_ip?(ip)
      !!IPAddr.new(ip) rescue false
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