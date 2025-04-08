# frozen_string_literal: true

module AerospikeService
  module Client
    class BaseClient
      include Operations::ReadOperations
      include Operations::WriteOperations
      include Operations::BatchOperations

      private

      def current_namespace
        AerospikeService.configuration.default_namespace
      end

      def connection_for_namespace(namespace)
        AerospikeService.connection_manager.connection_for(namespace)
      end
    end
  end
end
