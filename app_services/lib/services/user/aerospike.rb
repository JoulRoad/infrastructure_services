module Services
    module User
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
            
            def get_user_by_uuid(uuid, with_rank = false, skip_local_cache = false)
              begin
                ::NewRelic::Agent.add_custom_parameters({ uuid: uuid })
              rescue
              end
      
              return if uuid.blank? || uuid.include?('-')
      
              val = get_user_from_local_cache(uuid, skip_local_cache)
              if val.nil?
                val = ::User::HttpClient.fetch_user_from_service(uuid)
                return if val.blank?
      
                val.delete("credits")
      
                %w[email_id _id].each do |key|
                  add_user_info_to_cache([val[key], val.to_json]) if val[key].present?
                end
      
                val["uuid"] ||= val.dig("_id", "$oid")
                val["name"] = val["name"]&.downcase&.split&.uniq&.join(" ")&.titleize
      
                add_city_rank_info(val) if with_rank
                update_user_pic_origin(val)
              else
                val["uuid"] ||= val.dig("_id", "$oid")
                val["name"] = format_user_name(val)
                update_user_pic_origin(val)
                add_city_rank_info(val) if with_rank
              end
      
              val
            end
      
            def get_user_from_local_cache(id, skip_local_cache = false)
              @@user_data ||= {}
              return @@user_data[id] if @@user_data[id].present? && !skip_local_cache
      
              data = get_users_from_cache([id])[id]
              return nil if data.blank?
      
              begin
                data = JSON.parse(data)
              rescue JSON::ParserError
                return nil
              end
      
              if data.present?
                @@user_data[data["email_id"]&.downcase] = data if data["email_id"].present?
                @@user_data[data.dig("_id", "$oid")] = data if data.dig("_id", "$oid").present?
              end
              data
            end
      
            def get_users_from_cache(ids)
              ret_obj = {}
              return ret_obj if ids.blank?
      
              user_objs = $as_userDatabase.mget(keys: ids, setname: Constants::AerospikeUserObjectSetname, bins: "default")
              ids.each_with_index { |id, i| ret_obj[id] = user_objs[i] }
              ret_obj
            end
      
            def add_user_info_to_cache(hmset_users)
              hmset_users.each_slice(2) do |p_key, value|
                $as_userDatabase.set(
                  key: p_key,
                  setname: Constants::AerospikeUserObjectSetname,
                  value: value,
                  expiration: 7.days.to_i
                )
              end
            end
      
            def add_city_rank_info(user)
              return if user.blank?
              user_rank_data = $as_nc_userDatabase.get(
                key: (user["uuid"] || user.dig("_id", "$oid")),
                setname: "scrapbookers",
                bins: "default"
              )
      
              if user_rank_data.present?
                user_rank_data = JSON.parse(user_rank_data)
                if user["city"].present? && user["city"] == user_rank_data["city"]
                  user["cityRank"] = user_rank_data["cityRank"] || ""
                end
              end
            end
      
            def update_user_pic_origin(user)
              return if user.blank?
              ["pic", "tnpic"].each do |key|
                if user[key].present?
                  user[key] = ImageLinkHelper.replace_origin(user[key])
                end
              end
            end
          end
        end
    end
      
end