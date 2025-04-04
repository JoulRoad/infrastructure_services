# frozen_string_literal: true

require "rails/generators/base"

module AerospikeService
  module Generators
    # Generator for creating AerospikeService configuration file
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __dir__)

      desc "Creates a AerospikeService configuration file"

      # Create configuration file
      def create_config_file
        template "aerospike_service.yml", "config/aerospike_service.yml"
      end

      # Create initializer
      def create_initializer
        template "aerospike_service.rb", "config/initializers/aerospike_service.rb"
      end

      # Display readme
      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
