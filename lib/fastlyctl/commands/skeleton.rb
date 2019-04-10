module FastlyCTL
  class CLI < Thor
    desc "skeleton NAME", "Create a skeleton VCL file with the current boilerplate."
    method_option :service, :aliases => ["--s"]
    def skeleton(name="main")
      id = FastlyCTL::Utils.parse_directory unless options[:service]
      id ||= options[:service]
      abort "Could not parse service id from directory. Use --s <service> to specify, vcl download, then try again." unless id

      filename = "#{name}.vcl"
      version = FastlyCTL::Fetcher.get_active_version(id)
      boilerplate = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/boilerplate")

      if (File.exist?(filename))
        say("#{filename} exists, please delete it if you want this command to overwrite it.")
        abort
      end

      File.open(filename , 'w+') {|f| f.write(boilerplate) }

      say("Boilerplate written to #{filename}.")
    end
  end
end
