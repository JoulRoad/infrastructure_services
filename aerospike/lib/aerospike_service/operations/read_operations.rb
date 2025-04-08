# frozen_string_literal: true

module AerospikeService
  module Operations
    module ReadOperations
      def get(key:, namespace: nil, bin: nil)
        namespace ||= current_namespace
        connection = connection_for_namespace(namespace)

        key_str = key.to_s

        aerospike_key = Aerospike::Key.new(namespace, "test", key_str)
        options = bin ? [bin.to_s] : nil

        begin
          record = options ? connection.get(aerospike_key, options) : connection.get(aerospike_key)
          return nil unless record

          if bin && record.bins.key?(bin.to_s)
            record.bins[bin.to_s]
          else
            record.bins
          end
        rescue Aerospike::Exceptions::Aerospike => e
          return nil if e.message.include?("not found")

          if e.message.include?("Invalid namespace")
            warn "Warning: Invalid namespace '#{namespace}'. Please check your Aerospike configuration."
            return nil
          end

          raise OperationError, "Error getting record: #{e.message}"
        rescue => e
          raise OperationError, "Error getting record: #{e.message}"
        end
      end

      def exists?(key:, namespace: nil)
        namespace ||= current_namespace
        connection = connection_for_namespace(namespace)

        key_str = key.to_s

        aerospike_key = Aerospike::Key.new(namespace, "test", key_str)

        begin
          connection.exists(aerospike_key)
        rescue Aerospike::Exceptions::Aerospike => e
          return false if e.message.include?("not found")

          if e.message.include?("Invalid namespace")
            warn "Warning: Invalid namespace '#{namespace}'. Please check your Aerospike configuration."
            return false
          end

          raise OperationError, "Error checking record existence: #{e.message}"
        rescue => e
          raise OperationError, "Error checking record existence: #{e.message}"
        end
      end

      def record(key:, namespace: nil)
        namespace ||= current_namespace
        bins = get(key: key, namespace: namespace)
        return nil unless bins

        Models::Record.new(key: key, bins: bins, namespace: namespace)
      end

      private

      def current_namespace
        raise NotImplementedError, "Subclasses must implement #current_namespace"
      end
    end
  end
end
