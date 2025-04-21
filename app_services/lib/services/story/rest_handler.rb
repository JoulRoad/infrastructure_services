module Services
    module Story
      module RestHandler
        class << self
          def fetch_stories_by_ids(story_ids, fields_to_be_fetched)
            return nil unless story_ids.is_a?(Array) && story_ids.any?
  
            base_url = ServicesConfig.config['final_user_service_url']
            query    = URI.encode("story/get_stories_by_id?story_ids=#{story_ids}")
            uri      = URI.parse(base_url).merge!(query)
  
            response = begin
              Net::HTTP.start(uri.host, uri.port) do |http|
                http.request(Net::HTTP::Get.new(uri.request_uri))
              end
            rescue Errno::ECONNREFUSED
              return []
            end
  
            return [] unless response.code == '200'
  
            raw = JSON.parse(response.body)
            return [] if raw.blank?
  
            raw.map { |story| story.slice(*fields_to_be_fetched) }
          end
  
          def fetch_story_by_id(id, fields_to_be_fetched)
            base_url     = ServicesConfig.config['final_user_service_url']
            query        = "story/get_story_by_id?story_id=#{id}"
            rest_handler = RestHandler.new(url: base_url, query: query)
            data         = rest_handler.send_get_call(0.5)
            return nil unless data.present?
  
            data.slice(*fields_to_be_fetched)
          rescue Errno::ECONNREFUSED
            nil
          end
        end
      end
    end
  end