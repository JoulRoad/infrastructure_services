require "yaml"
require_relative "base_config"

module Config
  class YMLConfig < BaseConfig
    def should_convert?
      config = YAML.load_file(config_file)
      config.key?("namespaces") && config["namespaces"].is_a?(Array)
    rescue Errno::ENOENT, Psych::SyntaxError
      false
    end

    def convert_config
      YAML.load_file(config_file)
    rescue => e
      warn "YML config error: #{e.message}"
      {}
    end
  end
end
