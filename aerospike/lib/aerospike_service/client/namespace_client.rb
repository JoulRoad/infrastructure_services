# frozen_string_literal: true

module AerospikeService
  module Client
    class NamespaceClient < BaseClient
      attr_reader :namespace_name

      def initialize(namespace_name:)
        @namespace_name = namespace_name
      end

      private

      def current_namespace
        namespace_name
      end
    end
  end
end
