# frozen_string_literal: true

module AerospikeService
  module Operations
    module WriteOperations
      DEFAULT_SETNAME = "default"
      DEFAULT_BIN_NAME = "default"
      RECORD_TOO_BIG = "Record too big"

      def delete(opts = {})
        key = opts.fetch(:key, nil)
        setname = opts.fetch(:setname, nil)
        namespace = opts.fetch(:namespace, current_namespace)

        begin
          connection = connection_for_namespace(namespace)
          aerospike_key = Aerospike::Key.new(namespace, setname, key.to_s)
          connection.delete(aerospike_key)
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
        key = opts.fetch(:key, nil)
        setname = opts.fetch(:setname, nil)
        expiration = opts.fetch(:expiration, nil)
        namespace = opts.fetch(:namespace, current_namespace)

        begin
          connection = connection_for_namespace(namespace)
          aerospike_key = Aerospike::Key.new(namespace, setname, key.to_s)
          record = connection.get(aerospike_key)
          return false unless record

          write_policy = Aerospike::WritePolicy.new
          write_policy.expiration = expiration

          connection.operate(aerospike_key, [Aerospike::Operation.touch], write_policy)
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
        key = opts.fetch(:key, nil)
        bin = opts.fetch(:bin, nil)
        incr_by = opts.fetch(:incr_by, 1)
        setname = opts.fetch(:setname, nil)
        expiration = opts.fetch(:expiration, nil)
        namespace = opts.fetch(:namespace, current_namespace)

        begin
          connection = connection_for_namespace(namespace)
          aerospike_key = Aerospike::Key.new(namespace, setname, key.to_s)
          operation = Aerospike::Operation.add(Aerospike::Bin.new(bin, incr_by))

          write_policy = nil
          if expiration
            write_policy = Aerospike::WritePolicy.new
            write_policy.expiration = expiration
          end

          connection.operate(aerospike_key, [operation], write_policy)
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
        key = opts.fetch(:key, nil)
        value = opts.fetch(:value, nil)
        expiration = opts.fetch(:expiration, -1)
        setname = opts.fetch(:setname, DEFAULT_SETNAME)
        namespace = opts.fetch(:namespace, current_namespace)

        begin
          connection = connection_for_namespace(namespace)
          aerospike_key = Aerospike::Key.new(namespace, setname, key.to_s)

          value = value.is_a?(Hash) ? value.transform_keys(&:to_s) : {DEFAULT_BIN_NAME => value}
          enable_convert_booleans = opts.fetch(:convert_boolean_values, false)
          value = convert_boolean_values(bins: value, bool_to_string: true) if enable_convert_booleans

          connection.put(aerospike_key, value, expiration: expiration)
          true
        rescue Aerospike::Exceptions::Aerospike => e
          if e.message == RECORD_TOO_BIG
            puts "Big Data is being set -> {key: #{key}, setname: #{setname}, expiration: #{expiration}}\n value => #{value}\n#{caller[0..4].join("\n")}"
          end
          raise OperationError, "Error setting record: #{e.message}"
        rescue => e
          raise OperationError, "Error setting record: #{e.message}"
        end
      end

      private

      def convert_boolean_values(opts = {})
        bins = opts.fetch(:bins)
        bool_to_string = opts.fetch(:bool_to_string, false)

        if bins.is_a?(Hash)
          bins.map do |bin, value|
            [bin, convert_boolean_values(bins: value, bool_to_string: bool_to_string)]
          end.to_h
        elsif bins.is_a?(Array)
          bins.map { |bin| convert_boolean_values(bins: bin, bool_to_string: bool_to_string) }
        elsif bins.is_a?(String)
          if bins == "true"
            bool_to_string ? bins : true
          elsif bins == "false"
            bool_to_string ? bins : false
          else
            bins
          end
        elsif bins == true
          bool_to_string ? "true" : bins
        elsif bins == false
          bool_to_string ? "false" : bins
        else
          bins
        end
      end
    end
  end
end
