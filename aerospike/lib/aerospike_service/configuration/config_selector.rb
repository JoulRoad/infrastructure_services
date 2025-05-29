module Config
  class ConfigSelector < BaseConfig
    def self.setup(mode)
      case mode.to_s
      when "yml"
        YMLConfig.new(BaseConfig.yml_file)
      when "zookeeper"
        ZookeeperConfig.new(BaseConfig.zookeeper_file)
      else
        raise ArgumentError, "Unknown config mode: #{mode}"
      end
    end
  end
end
