module FastlyCTL
  class CLI < Thor
    desc "clone SERVICE_ID TARGET_SERVICE_ID", "Clone a service version to another service."
    method_option :version, :aliases => ["--v"]
    method_option :skip_logging, :aliases => ["--sl"]
    def clone(id,target_id)
      version = FastlyCTL::Fetcher.get_active_version(id) unless options[:version]
      version ||= options[:version]

      target_version = FastlyCTL::Fetcher.api_request(:post, "/service/#{target_id}/version")["number"]

      puts "Copying #{id} version #{version} to #{target_id} version #{target_version}..."

      FastlyCTL::CloneUtils::OBJECT_TYPES.each do |type,meta|
        next if (type.include?("logging/") && options.key?(:skip_logging))

        response = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/#{type}")
        response = [response] unless response.is_a?(Array)

        next unless response.length > 0

        puts "Copying #{response.length} " + (response.length == 1 ? FastlyCTL::CloneUtils.unpluralize(type) : FastlyCTL::CloneUtils.pluralize(type))

        response.each do |obj|
          FastlyCTL::CloneUtils.copy(obj,type,target_id,target_version)
        end
      end

      target_active_version = FastlyCTL::Fetcher.get_active_version(target_id)
      response = FastlyCTL::Fetcher.api_request(:get, "/service/#{target_id}/version/#{target_active_version}/domain")
      return unless response.length > 0

      puts "Restoring #{response.length} " + (response.length == 1 ? "domain" : "domains" + " from #{target_id} version #{target_active_version}...")

      response.each do |domain|
        FastlyCTL::CloneUtils.copy(domain,"domain",target_id,target_version)
      end
    end
  end
end
