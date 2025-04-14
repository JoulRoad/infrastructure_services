module Services
    module Story
        module Redis
          class << self
            # Global dependency check:
            begin
                require "redis" # Your custom gem
            rescue LoadError
                raise "The 'redis' gem is required for Redis functionality. Add 'gem \"redis\"' to your Gemfile."
            end
  
            def self.client
                @client ||= RedisGem::Client.new # Adjust based on your gem's initialization
            end
            
            def get_stories_from_cache_by_ids(story_ids)
              return {} if story_ids.blank?
              stories = $as_userDatabase.mget(keys: story_ids, setname: "stories", bins: ["default"])
              Hash[story_ids.zip(stories)].reject { |_, v| v.blank? }
            end
      
            def set_stories_in_cache(story_map)
              expiration = APP_CONFIG["story"]["redis_expiry_time"].to_i.days.to_i
      
              story_map.each do |id, story|
                begin
                  $as_userDatabase.set(
                    key: id,
                    setname: "stories",
                    value: { "default" => story },
                    expiration: expiration
                  )
                rescue Aerospike::Exceptions::Aerospike => e
                  Rails.logger.error("Error setting story #{id}: #{e.message}")
                  raise e unless e.message == "Record too big"
                end
              end
            end
          end
        end
    end   
end