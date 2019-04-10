module FastlyCTL
  class CLI < Thor
    desc "activate", "Activates the latest writable service version, or the version number provided in the --version flag."
    method_option :service, :aliases => ["--s"]
    method_option :version, :aliases => ["--v"]
    method_option :comment, :aliases => ["--c"]
    def activate
      id = FastlyCTL::Utils.parse_directory unless options[:service]
      id ||= options[:service]

      abort "Could not parse service id from directory. Use --s <service> to specify, vcl download, then try again." unless id

      writable_version = FastlyCTL::Fetcher.get_writable_version(id) unless options[:version]
      writable_version ||= options[:version].to_i

      if options.key?(:comment)
        FastlyCTL::Fetcher.api_request(:put, "/service/#{id}/version/#{writable_version}",{
          params: {comment: options[:comment]}
        })
      end

      FastlyCTL::Fetcher.api_request(:put, "/service/#{id}/version/#{writable_version}/activate")

      say("Version #{writable_version} on #{id} activated.")
    end
  end
end
