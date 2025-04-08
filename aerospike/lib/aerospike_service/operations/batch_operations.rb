# frozen_string_literal: true

module AerospikeService
  module Operations
    module BatchOperations
      def batch_get(keys:, namespace: nil, bin: nil)
        namespace ||= current_namespace
        connection = connection_for_namespace(namespace)

        # Implement a basic batch get operation manually
        begin
          results = {}

          keys.each do |k|
            # Create key for each record
            key_str = k.to_s
            aerospike_key = Aerospike::Key.new(namespace, "test", key_str)

            # Get options
            options = bin ? [bin.to_s] : nil  # Use bin array for bin_names

            # Get record using positional arguments
            record = options ? connection.get(aerospike_key, options) : connection.get(aerospike_key)

            results[k] = if record
              if bin && record.bins.key?(bin.to_s)
                record.bins[bin.to_s]
              else
                record.bins
              end
            end
          rescue Aerospike::Exceptions::Aerospike => e
            Rails.logger.error("Aerospike error: #{e.message}")
            # Record not found, add nil result
            results[k] = nil
          rescue => e
            Rails.logger.error("Error getting record for key #{k}: #{e.message}")
            # Skip errors for individual records
            results[k] = nil
          end

          results
        rescue => e
          raise OperationError, "Error batch getting records: #{e.message}"
        end
      end
    end
  end
end
