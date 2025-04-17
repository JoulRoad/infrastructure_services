# frozen_string_literal: true

module AerospikeService
  module Operations
    module WriteOperations
      AS_DEFAULT_BIN_NAME = "default"
      RECORD_TOO_BIG = "Record too big"
      AS_DEFAULT_SETNAME = "default"

      def delete(opts = {})
        key = opts.fetch(:key)
        namespace = opts.fetch(:namespace, current_namespace)
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

      def touch(opts = {})
        key = opts.fetch(:key)
        ttl = opts.fetch(:ttl, nil)
        namespace = opts.fetch(:namespace, current_namespace)
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

      def increment(opts = {})
        key = opts.fetch(:key)
        bin = opts.fetch(:bin)
        incr_by = opts[:incr_by] || opts.fetch(:value, 1)
        namespace = opts.fetch(:namespace, current_namespace)
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

          connection.put(aerospike_key, {bin.to_s => current_val + incr_by})
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

      def set(opts = {})
        key = opts.fetch(:key)
        value = opts.fetch(:value)
        namespace = opts.fetch(:namespace, current_namespace)
        setname = opts.fetch(:setname, AS_DEFAULT_SETNAME)
        expiration = opts.fetch(:expiration, -1)
        enable_convert_booleans = opts.fetch(:convert_boolean_values, false)
        value = value.is_a?(Hash) ? value : {"value" => value}

        connection = connection_for_namespace(namespace)
        key_str = key.to_s
        aerospike_key = Aerospike::Key.new(namespace, setname, key_str)

        value = value.is_a?(Hash) ? value.transform_keys(&:to_s) : {AS_DEFAULT_BIN_NAME => value}
        value = convert_boolean_values(bins: value, bool_to_string: true) if enable_convert_booleans

        connection.put(aerospike_key, value, expiration: expiration)
        true
      rescue Aerospike::Exceptions::Aerospike => e
        if e.message == RECORD_TOO_BIG
          LOGGER.error "Big Data is being set -> {key: #{key}, setname: #{setname}, expiration: #{expiration}}\n value => #{value}\n#{caller[0..4].join("\n")}"
        end
        raise OperationError, "Error setting record: #{e.message}"
      rescue => e
        raise OperationError, "Error setting record: #{e.message}"
      end
    end
  end
end
