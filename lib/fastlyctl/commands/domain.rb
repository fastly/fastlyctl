module FastlyCTL
  class CLI < Thor
    desc "domain ACTION HOST", "Manipulate domains on a service. Available actions are create, delete, list and check. Create, delete and check take a host argument. Additionally, check can take the argument \"all\" to check all domains."
    method_option :service, :aliases => ["--s"]
    method_option :version, :aliases => ["--v"]
    def domain(action,host=false)
      id = FastlyCTL::Utils.parse_directory unless options[:service]
      id ||= options[:service]

      abort "Could not parse service id from directory. Use --s <service> to specify, vcl download, then try again." unless id

      readonly = ["list", "check"]

      version = FastlyCTL::Fetcher.get_service_version(id, readonly.include?(action)) unless options[:version]
      version ||= options[:version].to_i

      case action
      when "create"
        FastlyCTL::Fetcher.api_request(:post,"/service/#{id}/version/#{version}/domain",{
          params: {
            name: host,
          }
        })
        say("#{host} created on #{id} version #{version}")
      when "delete"
        FastlyCTL::Fetcher.api_request(:delete,"/service/#{id}/version/#{version}/domain/#{host}")
        say("#{host} deleted on #{id} version #{version}")
      when "list"
        domains = FastlyCTL::Fetcher.api_request(:get,"/service/#{id}/version/#{version}/domain")
        say("Listing all domains for #{id} version #{version}")
        domains.each do |d|
          puts d["name"]
        end
      when "check"
        if host == "all"
          domains = FastlyCTL::Fetcher.api_request(:get,"/service/#{id}/version/#{version}/domain/check_all")
        else
          domains = [FastlyCTL::Fetcher.api_request(:get,"/service/#{id}/version/#{version}/domain/#{host}/check")]
        end

        domains.each do |d|
          say("#{d[0]["name"]} -> #{d[1]}")
        end
      else
        abort "#{action} is not a valid command"
      end
    end
  end
end
