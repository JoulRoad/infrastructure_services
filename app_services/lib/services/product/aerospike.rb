module Services
  module Product
    module Aerospike
      begin
        require 'aerospike'
      rescue LoadError
        raise "The 'aerospike' gem is required for Aerospike functionality. " \
              "Add 'gem \"aerospike\"' to your Gemfile."
      end

      ProductSetnameFieldCount = 6.freeze

      class << self
        def client
          @client ||= AerospikeGem::Client.new
        end

        def fetch_products_by_ids(ids, bins, fields_to_be_fetched)
          return {} if ids.blank?

          records = client.mget(ids, 'upid_data', bins)

          values = if records.blank?
                     []
                   else
                     records.each_with_object([]) do |record, arr|
                       if record.present?
                         fields_to_be_fetched.each { |field| arr << record[field] }
                       else
                         fields_to_be_fetched.size.times { arr << nil }
                       end
                     end
                   end

          ids.each_with_index.inject({}) do |result, (id, index)|
            base_index = ProductSetnameFieldCount * index

            field_values = fields_to_be_fetched.each_with_index.map do |field, field_index|
              value = values[base_index + field_index]

              if field == 'qualityRating'
                { 'quality' => value }.to_json
              else
                value
              end
            end

            result.merge({ id => field_values })
          end
        end

        def fetch_product_by_id(id, bins,fields_to_be_fetched)
          fetch_products_by_ids([id], bins, fields_to_be_fetched)[id]
        end
      end
    end
  end
end