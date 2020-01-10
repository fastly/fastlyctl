require "fastlyctl/commands/tls/managed"

module FastlyCTL
  class TLSSubCmd < Thor 
    namespace :tls

    # bit of a monkey patch to fix --help output
    def self.banner(command, namespace = nil, subcommand = false)
      "#{basename} tls #{command.usage}"
    end
  end

  class CLI < Thor
    desc "tls SUBCOMMAND ...ARGS", "Interface with Fastly TLS"
    subcommand "tls", TLSSubCmd
  end

  module TLSUtils
    def self.get_tls_config
      data = FastlyCTL::Fetcher.api_request(:get,"/tls/configurations")
      if data["data"].length == 0
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
      if configs.length == 1
        say "Using TLS Configuration #{configs[0]["id"]} - #{configs[0]["name"]}"
        return configs[0]
      end

      loop do
        i = 1
        configs.each do |c|
          pp c
          say("[#{i}] #{c["id"]} - #{c["name"]}")
          i += 1
        end

        selected = ask("Which TLS Configuration would you like to use? Please type the number next to the configuration(s) above.").to_i
        if selected > 0 && selected <= (configs.length+1)
          selected -= 1
          say "Using TLS Configuration #{configs[selected]["id"]} - #{configs[selected]["name"]}"
          return configs[selected]
        end

        say "#{selcted} is in invalid selection. Please try again."
      end
    end
  end
end
