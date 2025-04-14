module Services 
    module User
        module RestHandler
          class << self
            def fetch_user_from_service(uuid)
              query = URI.encode_www_form(user_uid: uuid)
              base_url = ServicesConfig.config['user_service_url']
              uri = URI.parse(base_url).merge("get_user_by_uid?#{query}")
      
              begin
                response = Net::HTTP.get_response(uri)
              rescue StandardError => _e
                return nil
              end
      
              return nil unless response&.code == "200"
      
              begin
                JSON.parse(response.body)
              rescue JSON::ParserError
                nil
              end
            end
          end
        end
    end
      
end