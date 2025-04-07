# frozen_string_literal: true

module AerospikeService
  class Railtie < Rails::Railtie
    initializer "aerospike_service.configure" do |app|
      config_file = Rails.root.join("config", "aerospike_service.yml")
      if File.exist?(config_file)
        AerospikeService.load_configuration(config_file)
      end
    end

    rake_tasks do
      load "aerospike_service/tasks/aerospike.rake"
    end

    generators do
      require "aerospike_service/generators/install_generator"
      require "aerospike_service/generators/shortcuts_generator"
    end
  end
end
