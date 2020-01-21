module FastlyCTL
  class CLI < Thor
    desc "purge_all", "Purge all content from a service."
    method_option :service, :aliases => ["--s"]
    def purge_all
      id = FastlyCTL::Utils.parse_directory unless options[:service]
      id ||= options[:service]

      abort "Could not parse service id from directory. Use --s <service> to specify, vcl download, then try again." unless id

      FastlyCTL::Fetcher.api_request(:post, "/service/#{id}/purge_all")

      say("Purge all on #{id} completed.")
    end
  end
end
