module FastlyCTL
  class CLI < Thor
    desc "copy SERVICE_ID TARGET_SERVICE_ID OBJECT_TYPE OBJECT_NAME", "Copy an object from one service to another\n  Available Object Types: #{FastlyCTL::CloneUtils::OBJECT_TYPES.keys.join(', ')}"
    method_option :version1, :aliases => ["--v1"]
    method_option :version2, :aliases => ["--v2"]
    def copy(id,target_id,obj_type,obj_name=false)
      abort "Object name must be specified for all object types except settings" if (obj_name === false && obj_type != "settings")

      source_version = FastlyCTL::Fetcher.get_active_version(id) unless options[:version1]
      source_version ||= options[:version1]
      target_version = FastlyCTL::Fetcher.get_writable_version(target_id) unless options[:version2]
      target_version ||= options[:version2]

      unless FastlyCTL::CloneUtils::OBJECT_TYPES.include?(obj_type)
        abort "Object type #{obj_type} is invalid. Must be one of: #{FastlyCTL::CloneUtils::OBJECT_TYPES.keys.join(', ')}"
      end

      path = "/service/#{id}/version/#{source_version}/#{obj_type}"
      path += "/#{obj_name}" unless obj_type == "settings"
      obj = FastlyCTL::Fetcher.api_request(:get, path)

      encoded_name = URI.escape(obj_name)

      if (obj_type == "settings")
        puts "Copying settings from #{id} version #{source_version} to #{target_id} version #{target_version}..."
      else
        existing_obj = FastlyCTL::Fetcher.api_request(:get, "/service/#{target_id}/version/#{target_version}/#{obj_type}/#{encoded_name}",{
          expected_responses: [200,404]
        })

        if existing_obj.key?("name")
          abort unless yes?("A #{FastlyCTL::CloneUtils.unpluralize(obj_type)} named #{obj_name} already exists on #{target_id} version #{target_version}. Delete it and proceed?")

          FastlyCTL::Fetcher.api_request(:delete,"/service/#{target_id}/version/#{target_version}/#{obj_type}/#{encoded_name}")
        end

        puts "Copying #{FastlyCTL::CloneUtils.unpluralize(obj_type)} #{obj_name} from #{id} version #{source_version} to #{target_id} version #{target_version}..."
      end

      FastlyCTL::CloneUtils.copy(obj,obj_type,target_id,target_version)
    end
  end
end
