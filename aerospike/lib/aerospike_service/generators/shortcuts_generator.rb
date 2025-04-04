# frozen_string_literal: true

require "rails/generators/base"

module AerospikeService
  module Generators
    # Generator for creating shortcuts module for Aerospike namespaces
    class ShortcutsGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __dir__)

      desc "Creates shortcuts module for Aerospike namespaces"

      # Create shortcuts module
      def create_shortcuts_module
        template "aerospike.rb.tt", "lib/aerospike.rb"
      end

      # Display information
      def show_usage
        say "Shortcuts module created at lib/aerospike.rb"
        say "To use it, require 'aerospike' in your code."
      end
    end
  end
end
