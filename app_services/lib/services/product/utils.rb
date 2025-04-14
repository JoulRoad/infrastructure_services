module Services
    module Product
        module Utils 
            ProductSetnameFieldCount = 6.freeze
            def get_pricing_index
                time = Time.now.utc
                time.hour * 2 + (time.min >= 30 ? 1 : 0)
            end
        end
    end
end        