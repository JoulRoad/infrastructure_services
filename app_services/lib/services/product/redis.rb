module Services
    module Product
      module Redis
        # Global dependency check:
        begin
            require "redis" # Your custom gem
          rescue LoadError
            raise "The 'redis' gem is required for Redis functionality. Add 'gem \"redis\"' to your Gemfile."
          end
  
        def self.client
          @client ||= RedisGem::Client.new # Adjust based on your gem's initialization
        end
  
        def self.fetch_products_from_cache(ids, price_interval)
            ids.each_with_object({}) do |id, ret_map|
            key = "prodDataWithPrice:#{id}:#{price_interval}"
            value = client.get(key) # Adjust method call
            ret_map[id] = JSON.parse(value) if value.present?
          end
        end
  
        def self.cache_products(prod_map, price_interval)
            prod_map.each do |id, val_arr|
            key = "prodDataWithPrice:#{id}:#{price_interval}"
            client.set(key, val_arr) if val_arr.compact.present? # Adjust method call
          end
        end
      end
    end
  end