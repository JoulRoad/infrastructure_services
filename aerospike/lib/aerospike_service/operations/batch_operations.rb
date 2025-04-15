# frozen_string_literal: true

module AerospikeService
  module Operations
    module BatchOperations
      AS_DEFAULT_SETNAME = "test"
      AS_DEFAULT_BIN_NAME = "value"

      def batch_get(opts = {})
        keys = opts.fetch(:keys)
        namespace = opts.fetch(:namespace, current_namespace)
        bins = opts.fetch(:bins, [])
        setname = opts.fetch(:setname, AS_DEFAULT_SETNAME)

        connection = connection_for_namespace(namespace)
        results = {}

        keys.each do |k|
          key_str = k.to_s
          aerospike_key = Aerospike::Key.new(namespace, setname, key_str)

          begin
            options = bins.any? ? bins.map(&:to_s) : nil
            record = options ? connection.get(aerospike_key, options) : connection.get(aerospike_key)

            results[k] = if record
              if bins.any?
                (bins.length == 1) ? record.bins[bins.first.to_s] : record.bins.slice(*bins.map(&:to_s))
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
        end

        results
      rescue => e
        raise OperationError, "Error batch getting records: #{e.message}"
      end

      def mget(opts = {})
        keys = opts.fetch(:keys)
        bins = opts.fetch(:bins, nil)
        namespace = opts.fetch(:namespace, current_namespace)
        batch_size = opts.fetch(:batch_size, 30)
        setname = opts.fetch(:setname, AS_DEFAULT_SETNAME)

        connection = connection_for_namespace(namespace)
        results = []

        begin
          keys.map!(&:to_s)
          bin_array = bins ? Array(bins).map(&:to_s) : nil
          single_bin = bin_array&.size == 1

          keys.each_slice(batch_size) do |batch|
            aerospike_keys = batch.map { |key| Aerospike::Key.new(namespace, setname, key) }

            records = bin_array ? connection.batch_get(aerospike_keys, bin_array) : connection.batch_get(aerospike_keys)

            records.each do |record|
              if record.nil?
                results << nil
              else
                value = record.bins
                results << (single_bin ? value[bin_array.first] : value)
              end
            end
          end

          results
        rescue Aerospike::Exceptions::Aerospike => e
          if e.message.include?("Invalid namespace")
            warn "Warning: Invalid namespace '#{namespace}'. Please check your Aerospike configuration."
            return []
          end

          raise OperationError, "Error performing batch get: #{e.message}"
        rescue => e
          raise OperationError, "Error performing batch get: #{e.message}"
        end
      end

      def mget_all(opts = {})
        keys = opts.fetch(:keys)
        namespace = opts.fetch(:namespace, current_namespace)
        bins = opts.fetch(:bins, nil)
        setname = opts.fetch(:setname, AS_DEFAULT_SETNAME)

        connection = connection_for_namespace(namespace)

        keys = keys.map(&:to_s)
        aerospike_keys = keys.map { |key| Aerospike::Key.new(namespace, setname, key) }

        bins_array = Array(bins).map(&:to_s) if bins
        single_bin = bins_array&.length == 1

        begin
          records = connection.batch_get(aerospike_keys, bins_array, use_batch_direct: true)
          return [] unless records

          meta = {}
          records.each_with_index.map do |record, idx|
            if record.nil?
              nil
            else
              meta[keys[idx]] = {
                generation: record.generation,
                expiration: record.expiration
              }

              bin_data = record.bins
              single_bin ? bin_data[bins_array.first] : bin_data
            end
          end
        rescue Aerospike::Exceptions::Aerospike => e
          if e.message.include?("Invalid namespace")
            warn "Warning: Invalid namespace '#{namespace}'. Please check your Aerospike configuration."
            return []
          end

          raise OperationError, "Error during batch get: #{e.message}"
        rescue => e
          raise OperationError, "Error during batch get: #{e.message}"
        end
      end
    end
  end
end
