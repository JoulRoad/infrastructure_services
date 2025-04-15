# frozen_string_literal: true

module AerospikeService
  module Operations
    module WriteOperations

      AS_DEFAULT_BIN_NAME = "value"
      RECORD_TOO_BIG = "record too big"
      AS_DEFAULT_SETNAME = "test"

      def put(opts = {})
        key = opts.fetch(:key)
        bins = opts.fetch(:bins)
        ttl = opts.fetch(:ttl, nil)
        namespace = opts.fetch(:namespace, current_namespace)
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
        key      = opts.fetch(:key)
        ttl      = opts.fetch(:ttl, nil)
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
        key       = opts.fetch(:key)
        bin      = opts.fetch(:bin)
        value     = opts.fetch(:value, 1)
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

      def set(opts = {})
        key = opts.fetch(:key)
        value = opts.fetch(:value)
        namespace = opts.fetch(:namespace, current_namespace)
        setname = opts.fetch(:setname, AS_DEFAULT_SETNAME)
        expiration = opts.fetch(:expiration, -1)
        enable_convert_booleans = opts.fetch(:convert_boolean_values, false)

        connection = connection_for_namespace(namespace)
        key_str = key.to_s
        aerospike_key = Aerospike::Key.new(namespace, setname, key_str)

        unless value.is_a?(Hash)
          value = { AS_DEFAULT_BIN_NAME => value }
        else
          value = value.transform_keys(&:to_s)
        end

        if enable_convert_booleans
          value = convert_boolean_values(bins: value, bool_to_string: true)
        end

        connection.put(aerospike_key, value, expiration: expiration)

        true

      rescue Aerospike::Exceptions::Aerospike => e
        if e.message == RECORD_TOO_BIG
          $bigSessionLogger.error "Big Data is being set -> {key: #{key}, setname: #{setname}, expiration: #{expiration}}\n value => #{value}\n#{caller[0..4].join("\n")}"
        end
        raise OperationError, "Error setting record: #{e.message}"

      rescue => e
        raise OperationError, "Error setting record: #{e.message}"
      end


    end
  end
end
