# aerospike/lib/aerospike_service/generators/bundle_config_generator.rb
require "rails/generators/base"

module AerospikeService
  module Generators
    class BundleConfigGenerator < Rails::Generators::Base
      desc "Sets up Bundler configuration for local gem installation"

      def create_bundle_config
        create_file ".bundle/config", "---\nBUNDLE_PATH: \"vendor/bundle\"\n", force: true
        say_status :create, ".bundle/config", :green
      end

      def update_gitignore
        gitignore_path = ".gitignore"

        if File.exist?(gitignore_path)
          ignores = [
            "# Bundler configuration",
            "/.bundle/",
            "/vendor/bundle"
          ]

          append_to_file gitignore_path do
            existing_content = File.read(gitignore_path)
            new_entries = []

            ignores.each do |ignore|
              new_entries << ignore unless existing_content.include?(ignore)
            end

            new_entries.empty? ? "" : "\n#{new_entries.join("\n")}\n"
          end
        else
          create_file gitignore_path, "/.bundle/\n/vendor/bundle\n"
        end

        say_status :update, ".gitignore", :green
      end
    end
  end
end
