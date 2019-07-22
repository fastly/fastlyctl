module FastlyCTL
  class CLI < Thor
    desc "create_service SERVICE_NAME", "Create a blank service."
    def create_service(name)
      service = FastlyCTL::Fetcher.api_request(:post, "/service", { params: { name: name }})

      if yes?("Service #{service["id"]} has been created. Would you like to open the configuration page?")
        FastlyCTL::Utils.open_service(service["id"])
      end
    end
  end
end
