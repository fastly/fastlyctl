module FastlyCTL
  class CLI < Thor
    desc "purge_all", "Purge all content from a service."
    method_option :service, :aliases => ["--s"]
    def purge_all
      parsed_id = FastlyCTL::Utils.parse_directory

      id = FastlyCTL::Utils.parse_directory

      abort "Could not parse service id from directory. Use --s <service> to specify, vcl download, then try again." unless (id || options[:service])

      FastlyCTL::Fetcher.api_request(:post, "/service/#{id}/purge_all")

      say("Purge all on #{id} completed.")
    end
  end
end
