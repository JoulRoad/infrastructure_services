module Services
    module Story
        module Aerospike
          class << self 
            begin
                require "aerospike"
            rescue LoadError
                raise "The 'aerospike' gem is required for Aerospike functionality. Add 'gem \"aerospike\"' to your Gemfile."
            end
    
            def client
                @client ||= AerospikeGem::Client.new
            end
            
            def fetch_stories_by_ids(ids, bins, fields_to_be_fetched)
              return {} if ids.blank?
            
              stories = client.mget(ids, "stories", bins)
              
              processed_stories = stories.map do |story|
                next nil if story.blank?
                fields_to_be_fetched.map { |field| story[field] }
              end
              
              Hash[ids.zip(processed_stories)].reject { |_, v| v.blank? }
            end
            
            def fetch_story_by_id(id, bins, fields_to_be_fetched)
              story = client.get(id, "stories", bins)
              return nil if story.blank?
              fields_to_be_fetched.map { |field| story[field] }
            end

          end
        end
    end      
end