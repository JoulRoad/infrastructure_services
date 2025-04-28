# frozen_string_literal: true

require "rails/generators"

module RedisService
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)
      
      desc "Creates RedisService initializer files for configuration and shortcuts"
      
      def create_initializer
        template "initializer.rb.tt", "config/initializers/redis_service.rb"
      end
      
      def create_shortcuts
        template "shortcuts.rb.tt", "config/initializers/redis_shortcuts.rb"
      end
    end
  end
end 