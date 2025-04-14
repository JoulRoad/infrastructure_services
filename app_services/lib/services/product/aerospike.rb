module Services
    module Product
      module Aerospike
        # Global dependency check:
        begin
          require "aerospike" # Your custom gem
        rescue LoadError
          raise "The 'aerospike' gem is required for Aerospike functionality. Add 'gem \"aerospike\"' to your Gemfile."
        end
  
        # Now, since Aerospike is guaranteed to be available, you can define your methods without repetitive checks.
        def self.client
          @client ||= AerospikeGem::Client.new
        end
  
        def self.brand_rating_for_vendor(vendor_id)
          return nil unless vendor_id.present?
  
          response = client.get(vendor_id, "vendor_scores", "default")
          return nil if response.blank?
  
          json = JSON.parse(response)
          score = json.dig("scores", "AggregatedScore").to_f
          return nil if score.negative?
  
          score.round(1)
        rescue StandardError => e
          Rails.logger.error(e.inspect) if defined?(Rails)
          nil
        end
  
        def self.fetch_product_details_from_source(ids, price_interval)
          ret_hash = client.mget(
            ids,
            "upid_data",
            ["static", "price_#{price_interval}", "qualityRating", "static_video", "o2o_video", "feedbackUpid"]
          )
  
          tmp_arr = if ret_hash.blank?
                      []
                    else
                      ret_hash.inject([]) do |arr, map|
                        arr << (map.present? ? [
                          map["static"],
                          map["price_#{price_interval}"],
                          map["qualityRating"],
                          map["static_video"],
                          map["o2o_video"],
                          map["feedbackUpid"]
                        ] : [nil, nil, nil, nil, nil, nil])
                      end.flatten
                    end
  
          ids.each_with_index.each_with_object({}) do |(id, index), ret_map|
            base = Utils::ProductSetnameFieldCount * index
            quality = { "quality" => tmp_arr[base + 2] }
            ret_map[id] = [
              tmp_arr[base],
              tmp_arr[base + 1],
              quality.to_json,
              tmp_arr[base + 3],
              tmp_arr[base + 4],
              tmp_arr[base + 5]
            ]
          end
        end
      end
    end
end
  