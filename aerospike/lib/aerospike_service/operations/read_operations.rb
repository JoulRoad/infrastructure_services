# frozen_string_literal: true

module AerospikeService
  module Operations
    module ReadOperations
      DEFAULT_SETNAME = "default"
      DEFAULT_BIN_NAME = "default"

      def get(opts = {})
        key = opts.fetch(:key, nil)
        bins = opts.fetch(:bins, [])
        setname = opts.fetch(:setname, DEFAULT_SETNAME)
        namespace = opts.fetch(:namespace, current_namespace)

        begin
          connection = connection_for_namespace(namespace)

          options = bins.is_a?(String) ? [bins.to_s] : bins.map(&:to_s)
          options = nil if options.empty?

          aerospike_key = Aerospike::Key.new(namespace, setname, key.to_s)
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
        setname = opts.fetch(:setname, DEFAULT_SETNAME)
        namespace = opts.fetch(:namespace, current_namespace)

        begin
          connection = connection_for_namespace(namespace)
          aerospike_key = Aerospike::Key.new(namespace, setname, key.to_s)
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

      def by_rank_range_map_bin(opts = {})
        key = opts.fetch(:key, nil)
        bin = opts.fetch(:bin, DEFAULT_BIN_NAME)
        setname = opts.fetch(:setname, DEFAULT_SETNAME)
        namespace = opts.fetch(:namespace, current_namespace)
        begin_token = opts.fetch(:begin_token, nil)
        count = opts.fetch(:count, nil)
        expiration = opts.fetch(:expiration, nil)
        return_type = opts.fetch(:return_type, Aerospike::CDT::MapReturnType::KEY_VALUE)

        begin
          connection = connection_for_namespace(namespace)
          aerospike_key = Aerospike::Key.new(namespace, setname, key.to_s)
          operation = Aerospike::CDT::MapOperation.get_by_rank_range(
            bin, begin_token, count, return_type: return_type
          )
          result = connection.operate(aerospike_key, [operation], expiration: expiration)

          values = result&.bins&.[](bin)
          return ((return_type == Aerospike::CDT::MapReturnType::KEY_VALUE) ? {} : []) if values.nil?
          return values unless values.is_a?(Hash)

          values.map { |k, v| [k, -v] }
        rescue Aerospike::Exceptions::Aerospike => e
          if e.message.include?("Invalid namespace")
            warn "Warning: Invalid namespace '#{namespace}'. Please check your Aerospike configuration."
            return ((return_type == Aerospike::CDT::MapReturnType::KEY_VALUE) ? {} : [])
          end

          raise OperationError, "Error performing by_rank_range_map_bin: #{e.message}"
        rescue => e
          raise OperationError, "Error performing by_rank_range_map_bin: #{e.message}"
        end
      end
    end
  end
end
