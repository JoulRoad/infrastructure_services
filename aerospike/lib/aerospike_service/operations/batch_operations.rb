# frozen_string_literal: true

module AerospikeService
  module Operations
    module BatchOperations
      def batch_get(keys:, namespace: nil, bin: nil)
        namespace ||= current_namespace
        connection = connection_for_namespace(namespace: namespace)
        
        # Implement a basic batch get operation manually
        begin
          results = {}
          
          keys.each do |k|
            begin
              # Create key for each record
              key_str = k.to_s
              aerospike_key = Aerospike::Key.new(namespace, "test", key_str)
              
              # Get options
              options = bin ? [bin.to_s] : nil  # Use bin array for bin_names
              
              # Get record using positional arguments
              record = options ? connection.get(aerospike_key, options) : connection.get(aerospike_key)
              
              if record
                if bin && record.bins.key?(bin.to_s)
                  results[k] = record.bins[bin.to_s]
                else
                  results[k] = record.bins
                end
              else
                results[k] = nil
              end
            rescue Aerospike::Exceptions::Aerospike => e
              # Record not found, add nil result
              results[k] = nil
            rescue => e
              # Skip errors for individual records
              results[k] = nil
            end
          end
          
          results
        rescue => e
          raise OperationError, "Error batch getting records: #{e.message}"
        end
      end
    end
  end
end
