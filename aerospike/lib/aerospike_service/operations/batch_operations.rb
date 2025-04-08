# frozen_string_literal: true

module AerospikeService
  module Operations
    module BatchOperations
      def batch_get(keys:, namespace: nil, bin: nil)
        namespace ||= current_namespace
        connection = connection_for_namespace(namespace)

        begin
          results = {}

          keys.each do |k|
            key_str = k.to_s
            aerospike_key = Aerospike::Key.new(namespace, "test", key_str)

            options = bin ? [bin.to_s] : nil

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
            results[k] = nil
          rescue => e
            Rails.logger.error("Error getting record for key #{k}: #{e.message}")
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
