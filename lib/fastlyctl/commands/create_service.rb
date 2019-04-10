module FastlyCTL
  class CLI < Thor
    desc "create_service SERVICE_NAME", "Create a blank service. If --customer is supplied and you are an admin, the command will move the service to that customer's account."
    method_option :customer, :aliases => ["--c"]
    def create_service(name)
      service = FastlyCTL::Fetcher.api_request(:post, "/service", { params: { name: name }})

      if options[:customer]
        say("This command works by creating a service on your account and moving it to the target account.")
        self.move(service["id"],options[:customer])
      end

      if yes?("Service #{service["id"]} has been created. Would you like to open the configuration page?")
        FastlyCTL::Utils.open_service(service["id"])
      end
    end
  end
end
