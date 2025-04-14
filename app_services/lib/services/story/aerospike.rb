module Services
    module Story
        module Aerospike
          class << self 
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
            
            def get_stories_by_story_ids(story_ids, email: nil, basic_info: false, attr: [])
              result = []
              return result if story_ids.blank?
      
              cached_stories_map = ::Story::Cache.get_stories_from_cache_by_ids(story_ids)
              stories = cached_stories_map.values
              stories_not_in_cache = story_ids.reject { |story| story == "-1" } - cached_stories_map.keys
      
              if stories_not_in_cache.blank?
                result = stories + (story_ids.last == "-1" ? ["-1"] : [])
              else
                more_stories = Story::HttpClient.get_trimmed_stories_from_mongo_by_story_ids(stories_not_in_cache, email)
                if more_stories.blank?
                  result = stories + (story_ids.last == "-1" ? ["-1"] : [])
                else
                  result = stories + more_stories + (story_ids.last == "-1" ? ["-1"] : [])
                end
              end
      
              result.select { |story| story != "-1" }.map { |story| story.slice(*attr) }
            end
      
            def get_full_stories_by_stories_ids(story_ids, email: nil, basic_info: false, attr: [])
              story_data = get_stories_by_story_ids(story_ids, email: email, basic_info: basic_info, attr: attr)
              story_data.each_with_object({}) do |story, stories_map|
                if story.present? && story['story_id'].present?
                  stories_map[story['story_id']] = story
                end
              end
            end
          end
        end
    end      
end