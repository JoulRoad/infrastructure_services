# frozen_string_literal: true

require "rails/generators/base"

module AerospikeService
  module Generators
    class ShortcutsGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __dir__)

      desc "Creates shortcuts initializer for AerospikeService namespaces"

      def create_shortcuts_initializer
        template "aerospike_shortcuts.rb.tt", "config/initializers/aerospike_shortcuts.rb"
      end

      def show_usage
        say "Namespace shortcuts created at config/initializers/aerospike_shortcuts.rb"
        say "You can now use namespace shortcuts like:"
        say "  AerospikeService.users.get('key')"
        say "  AerospikeService.analytics.put('key', { data: 'value' })"
      end
    end
  end
end
