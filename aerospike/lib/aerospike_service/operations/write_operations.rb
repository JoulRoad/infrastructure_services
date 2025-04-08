# frozen_string_literal: true

module AerospikeService
  module Operations
    module WriteOperations
      def put(key:, bins:, namespace: nil, ttl: nil)
        namespace ||= current_namespace
        connection = connection_for_namespace(namespace)

        key_str = key.to_s

        aerospike_key = Aerospike::Key.new(namespace, "test", key_str)

        write_policy = nil
        if ttl
          write_policy = Aerospike::WritePolicy.new
          write_policy.ttl = ttl if write_policy.respond_to?(:ttl=)
        end

        begin
          formatted_bins = {}
          bins.each do |k, v|
            bin_name = k.to_s
            formatted_bins[bin_name] = v
          end

          if write_policy
            connection.put(aerospike_key, formatted_bins, write_policy)
          else
            connection.put(aerospike_key, formatted_bins)
          end
          true
        rescue Aerospike::Exceptions::Aerospike => e
          if e.message.include?("Invalid namespace")
            warn "Warning: Invalid namespace '#{namespace}'. Please check your Aerospike configuration."
            return false
          end

          raise OperationError, "Error putting record: #{e.message}"
        rescue => e
          raise OperationError, "Error putting record: #{e.message}"
        end
      end

      def delete(key:, namespace: nil)
        namespace ||= current_namespace
        connection = connection_for_namespace(namespace)

        key_str = key.to_s

        aerospike_key = Aerospike::Key.new(namespace, "test", key_str)

        begin
          connection.delete(aerospike_key)
          true
        rescue Aerospike::Exceptions::Aerospike => e
          return false if e.message.include?("not found")

          if e.message.include?("Invalid namespace")
            warn "Warning: Invalid namespace '#{namespace}'. Please check your Aerospike configuration."
            return false
          end

          raise OperationError, "Error deleting record: #{e.message}"
        rescue => e
          raise OperationError, "Error deleting record: #{e.message}"
        end
      end

      def touch(key:, namespace: nil, ttl: nil)
        namespace ||= current_namespace
        connection = connection_for_namespace(namespace)

        key_str = key.to_s

        aerospike_key = Aerospike::Key.new(namespace, "test", key_str)

        begin
          record = connection.get(aerospike_key)
          return false unless record

          write_policy = Aerospike::WritePolicy.new
          write_policy.ttl = ttl || 0 if write_policy.respond_to?(:ttl=)

          connection.put(aerospike_key, record.bins, write_policy)
          true
        rescue Aerospike::Exceptions::Aerospike => e
          return false if e.message.include?("not found")

          if e.message.include?("Invalid namespace")
            warn "Warning: Invalid namespace '#{namespace}'. Please check your Aerospike configuration."
            return false
          end

          raise OperationError, "Error touching record: #{e.message}"
        rescue => e
          raise OperationError, "Error touching record: #{e.message}"
        end
      end

      def increment(key:, bin:, value: 1, namespace: nil)
        namespace ||= current_namespace
        connection = connection_for_namespace(namespace)

        key_str = key.to_s

        aerospike_key = Aerospike::Key.new(namespace, "test", key_str)

        begin
          current_val = 0
          begin
            record = connection.get(aerospike_key)
            if record && record.bins[bin.to_s]
              current_val = record.bins[bin.to_s].to_i
            end
          rescue Aerospike::Exceptions::Aerospike => e
            if e.message.include?("Invalid namespace")
              warn "Warning: Invalid namespace '#{namespace}'. Please check your Aerospike configuration."
              return false
            end
          rescue => e
            Rails.logger.error "Error getting record for increment: #{e.message}"
          end

          connection.put(aerospike_key, {bin.to_s => current_val + value})
          true
        rescue Aerospike::Exceptions::Aerospike => e
          if e.message.include?("Invalid namespace")
            warn "Warning: Invalid namespace '#{namespace}'. Please check your Aerospike configuration."
            return false
          end

          raise OperationError, "Error incrementing record: #{e.message}"
        rescue => e
          raise OperationError, "Error incrementing record: #{e.message}"
        end
      end
    end
  end
end
