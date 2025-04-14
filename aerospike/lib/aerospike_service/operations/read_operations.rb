# frozen_string_literal: true

module AerospikeService
  module Operations
    module ReadOperations

      AS_DEFAULT_SETNAME = "test"
      def get(opts = {})
        key = opts.fetch(:key, nil)
        bins = opts.fetch(:bins, [])
        namespace = opts.fetch(:namespace, current_namespace)
        setname = opts.fetch(:setname, AS_DEFAULT_SETNAME)

        connection = connection_for_namespace(namespace)
        key_str = key.to_s

        aerospike_key = Aerospike::Key.new(namespace, setname, key_str)
        options = bins.is_a?(String) ? [bins.to_s] : bins.map(&:to_s)
        options = nil if options.empty?

        begin
          record = options ? connection.get(aerospike_key, options) : connection.get(aerospike_key)
          return nil unless record

          if bins.is_a?(String) && record.bins.key?(bins.to_s)
            record.bins[bins.to_s]
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


      def exists?(opts = {})

        key = opts.fetch(:key, nil)
        namespace = opts.fetch(:namespace, current_namespace)
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

      def record(opts = {})
        key = opts.fetch(:key, nil)
        namespace = opts.fetch(:namespace, current_namespace)
        bins = get(key: key, namespace: namespace)
        return nil unless bins

        Models::Record.new(key: key, bins: bins, namespace: namespace)
      end

      def by_rank_range_map_bin(opts = {})
        key          = opts.fetch(:key)
        namespace    = opts.fetch(:namespace, current_namespace)
        setname      = opts.fetch(:setname, AS_DEFAULT_SETNAME)
        bin          = opts.fetch(:bin, AS_DEFAULT_BIN_NAME)
        begin_token  = opts.fetch(:begin_token)
        count        = opts.fetch(:count)
        expiration   = opts.fetch(:expiration, nil)
        return_type  = opts.fetch(:return_type, Aerospike::CDT::MapReturnType::KEY_VALUE)

        connection = connection_for_namespace(namespace)
        aerospike_key = Aerospike::Key.new(namespace, setname, key.to_s)

        begin
          operation = Aerospike::CDT::MapOperation.get_by_rank_range(
            bin, begin_token, count, return_type: return_type
          )
          result = connection.operate(aerospike_key, [operation], expiration: expiration)

          values = result&.bins&.[](bin)

          return return_type == Aerospike::CDT::MapReturnType::KEY_VALUE ? {} : [] if values.nil?
          return values unless values.is_a?(Hash)

          values.map { |k, v| [k, -v] }
        rescue Aerospike::Exceptions::Aerospike => e
          if e.message.include?("Invalid namespace")
            warn "Warning: Invalid namespace '#{namespace}'. Please check your Aerospike configuration."
            return return_type == Aerospike::CDT::MapReturnType::KEY_VALUE ? {} : []
          end

          raise OperationError, "Error performing by_rank_range_map_bin: #{e.message}"
        rescue => e
          raise OperationError, "Error performing by_rank_range_map_bin: #{e.message}"
        end
      end


      private

      def current_namespace
        raise NotImplementedError, "Subclasses must implement #current_namespace"
      end

      def convert_boolean_values(opts = {})
        bins = opts.fetch(:bins)
        bool_to_string = opts.fetch(:bool_to_string, false)

        case
        when bins.is_a?(Hash)
          return Hash[bins.map do |bin, value|
            [bin, convert_boolean_values(bins: value, bool_to_string: bool_to_string)]
          end]
        when bins.is_a?(Array)
          return bins.map { |bin| convert_boolean_values(bins: bin, bool_to_string: bool_to_string) }
        when bins.is_a?(String)
          if bins == "true"
            return bool_to_string ? bins : true
          elsif bins == "false"
            return bool_to_string ? bins : false
          else
            return bins
          end
        when bins == true
          return bool_to_string ? "true" : bins
        when bins == false
          return bool_to_string ? "false" : bins
        end

        bins
      end

    end
  end
end
