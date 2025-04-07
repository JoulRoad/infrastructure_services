# frozen_string_literal: true

require "rails/generators/base"

module AerospikeService
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __dir__)

      desc "Creates an aerospike_service.yml configuration file"

      def create_config_file
        template "aerospike_service.yml.tt", "config/aerospike_service.yml"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
