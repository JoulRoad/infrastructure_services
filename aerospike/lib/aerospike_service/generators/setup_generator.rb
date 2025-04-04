# frozen_string_literal: true

require "rails/generators/base"

module AerospikeService
  module Generators
    class SetupGenerator < Rails::Generators::Base
      desc "Complete setup for AerospikeService (bundle config, install, shortcuts)"

      def setup_bundle_config
        generate "aerospike_service:bundle_config"
      end

      def setup_configuration
        generate "aerospike_service:install"
      end

      def setup_shortcuts
        if yes?("Would you like to generate namespace shortcuts? (y/n)")
          generate "aerospike_service:shortcuts"
        end
      end

      def show_completion_message
        say "\n🎉 AerospikeService setup complete!", :green
        say "You can now use AerospikeService in your application."
        say "Check config/aerospike_service.yml to customize your connection settings."
      end
    end
  end
end
