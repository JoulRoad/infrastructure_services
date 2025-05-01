# frozen_string_literal: true

module AerospikeService
  module Operations
    module BatchOperations
      AS_DEFAULT_SETNAME = "default"
      AS_DEFAULT_BIN_NAME = "default"

      def mget(opts = {})
        results = []
        batch_size = opts.fetch(:batch_size, 30)

        keys = opts.fetch(:keys, nil)
        return results if keys.nil? || keys.empty?

        begin
          keys.each_slice(batch_size) do |batch|
            results += mget_all(opts.merge({keys: batch}))
          end
          results
        rescue => e
          raise OperationError, "Error performing batch get: #{e.message}"
        end
      end

      def mget_all(opts = {})
        keys = opts.fetch(:keys, nil)
        return [] if keys.nil? || keys.empty?

        bins = opts.fetch(:bins, [])
        setname = opts.fetch(:setname, AS_DEFAULT_SETNAME)
        namespace = opts.fetch(:namespace, current_namespace)

        begin
          connection = connection_for_namespace(namespace)
          keys = keys.map { |key| (key.nil? || key.empty?) ? "" : key.to_s }
          aerospike_keys = keys.map { |key| Aerospike::Key.new(namespace, setname, key) }

          bins = bins.is_a?(String) ? [bins.to_s] : bins.map(&:to_s)

          records = connection.batch_get(aerospike_keys, bins, use_batch_direct: true)
          return [] unless records

          records.map do |record|
            if record.nil?
              nil
            else
              bin_data = record.bins
              (bins.size == 1) ? bin_data[bins.first] : bin_data
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
