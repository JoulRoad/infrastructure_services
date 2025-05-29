module Config
  class BaseConfig

    def self.yml_file
      @yml_file ||= File.expand_path('../../../spec/config/aerospike_static.yml', __FILE__)
    end

    def self.zookeeper_file
      @zk_file ||= File.expand_path('../../../spec/config/aerospike_service.yml', __FILE__)
    end

    attr_reader :config_file

    def initialize(config_file)
      @config_file = config_file
    end

    def should_convert?
      raise NotImplementedError
    end

    def convert_config
      raise NotImplementedError
    end
  end
end
