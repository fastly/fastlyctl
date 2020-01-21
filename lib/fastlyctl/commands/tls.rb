require "fastlyctl/commands/tls/managed"

module FastlyCTL
  class CLI < Thor
    desc "tls SUBCOMMAND ...ARGS", "Interface with Fastly TLS"
    subcommand "tls", TLSSubCmd
  end

  module TLSUtils
    def self.get_tls_configs
      data = FastlyCTL::Fetcher.api_request(:get,"/tls/configurations",{use_vnd:true})["data"]
      if data.length == 0
        thor = Thor::Shell::Basic.new
        thor.say "No TLS Configurations found. You may need to upgrade to a paid account if you are using a free account."
        thor.say "If you need assistance, please contact support@fastly.com."
        if (thor.yes?("Would you like to open the TLS configuration page in the Fastly app?"))
          FastlyCTL::Utils.open_app_path("/network/domains")
        end
        abort
      end

      return data
    end

    def self.select_tls_config(configs)
      thor = Thor::Shell::Basic.new
      if configs.length == 1
        thor.say "Using TLS Configuration #{configs[0]["id"]} - #{configs[0]["name"]}"
        return configs[0]
      end

      loop do
        i = 1
        configs.each do |c|
          bulk = c["attributes"]["bulk"] ? " [Platform TLS]" : ""
          thor.say("[#{i}]#{bulk} #{c["id"]} - #{c["name"]}\n")
          i += 1
        end

        selected = thor.ask("Which TLS Configuration would you like to use? Please type the number next to the configuration(s) above.").to_i
        if selected > 0 && selected <= (configs.length+1)
          selected -= 1
          thor.say "Using TLS Configuration #{configs[selected]["id"]} - #{configs[selected]["name"]}"
          return configs[selected]
        end

        thor.say "#{selcted} is in invalid selection. Please try again."
      end
    end

    def self.print_challenges(tls_authorization)
      thor = Thor::Shell::Basic.new
      thor.say "\nIn order to verify your ownership of the domain, the Certificate Authority provided the following challenges:"
      tls_authorization["attributes"]["challenges"].each do |challenge|
        thor.say("\n#{challenge["type"]}: Create #{challenge["record_type"]} record for #{challenge["record_name"]} with value(s) of:")
        challenge["values"].each do |val|
          thor.say("    #{val}")
        end
      end
      thor.say("\nNote: If you don't want to move all traffic to Fastly right now, use the managed-dns option. The other options result in traffic for that hostname being directed to Fastly.")
    end
  end
end
