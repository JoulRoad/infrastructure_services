module Services
    module Story
        module Fetcher 
            class << self
                def fetch_stories_by_ids(ids, bins, fields_to_be_fetched)
                    result = []
                    return result if ids.blank?
                    
                    cached_stories_map = Services::Story::Aerospike.fetch_stories_by_ids(ids, bins, fields_to_be_fetched)
                  
                    stories = cached_stories_map.values.map do |story|
                      story.is_a?(String) ? JSON.parse(story) : story
                    end
                    
                    stories_in_cache = cached_stories_map.keys
                    stories_not_in_cache = ids.reject { |story| story == "-1" } - stories_in_cache
                    
                    if stories_not_in_cache.blank?
                      result = stories + (ids.last == "-1" ? ["-1"] : [])
                    else
                      more_stories = Services::Story::RestHandler.fetch_stories_by_ids(stories_not_in_cache, fields_to_be_fetched)
                      if more_stories.blank?
                        result = stories + (ids.last == "-1" ? ["-1"] : [])
                      else
                        result = stories + more_stories + (ids.last == "-1" ? ["-1"] : [])
                      end
                    end
                    
                    result.select { |story| story != "-1" }
                end

                def get_story_by_id(id, bins, fields_to_be_fetched)
                    return nil if id.blank?
                    story_data = Services::Story::Aerospike.fetch_story_by_id(id, bins, fields_to_be_fetched)
                    
                    if story_data.blank?
                      story_data = Services::Story::RestHandler.fetch_story_by_id(id, fields_to_be_fetched)
                      return {} unless story_data.present?
                    else
                      story_data = JSON.parse(story_data)
                    end
                    story_data
                end
            end    
        end
    end
end