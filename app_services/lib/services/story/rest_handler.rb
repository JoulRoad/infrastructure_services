module Services
    module Story
        module RestHandler
          class << self
            def get_trimmed_stories_by_story_ids(story_ids)
              return [] if story_ids.blank? || !story_ids.is_a?(Array)
      
              query_params = { story_ids: story_ids }
              query_string = URI.encode_www_form(query_params)
      
              base_url = ServicesConfig.config['final_user_service_url']
              uri = URI.join(base_url, "story/get_stories_by_id?#{query_string}")
      
              begin
                response = Net::HTTP.get_response(uri)
              rescue Errno::ECONNREFUSED
                return []
              end
      
              return [] unless response&.code == "200"
      
              begin
                JSON.parse(response.body)
              rescue JSON::ParserError
                []
              end
            end
          end
        end
    end  
end