module FastlyCTL
  class TLSManagedSubCmd < SubCommandBase
    SubcommandPrefix = "tls managed"
    DomainRegex = /(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9][a-z0-9-]{0,61}[a-z0-9]/

    desc "create <domain>", "Create a Fastly Managed TLS Subscription for [domain]. A Certificate will be requested from lets-encrypt once you satisfy one of the challenges. You can learn more about the challenge types here: https://letsencrypt.org/docs/challenge-types/ and Fastly's API documentation here: https://docs.fastly.com/api/tls-subscriptions."
    def create(domain)
      abort "Must specify valid domain name" unless domain =~ DomainRegex

      tls_configs = FastlyCTL::TLSUtils.get_tls_configs
      tls_config = FastlyCTL::TLSUtils.select_tls_config(tls_configs)

      payload = {
        data: {
          type: "tls_subscription",
          attributes: {
            certificate_authority: "lets-encrypt"
          },
          relationships: {
            tls_domains: {
              data: [
                {
                  type: "tls_domain",
                  id: domain
                }
              ]
            },
            tls_configuration: {
              data: {
                type: "tls_configuration",
                id: tls_config["id"]
              }
            }
          }
        }
      }

      subscription = FastlyCTL::Fetcher.api_request(:post,"/tls/subscriptions", {
        body: payload.to_json,
        use_vnd: true
      })

      tls_authorization = FastlyCTL::Utils.filter_vnd(subscription["included"],"tls_authorization")
      abort "Unable to fetch TLS Authorization for the domain." unless tls_authorization.length > 0
      FastlyCTL::TLSUtils.print_challenges(tls_authorization[0])
    end

    desc "status", "Print status of Fastly Managed TLS Subscriptions"
    def status
      subscriptions = FastlyCTL::Fetcher.api_request(:get,"/tls/subscriptions", {
        use_vnd: true
      })

      if subscriptions["data"].length == 0
        say("No Fastly Managed TLS Subscriptions found.")
        abort
      end

      subscriptions["data"].each do |subscription|
        output = subscription["relationships"]["tls_domains"]["data"][0]["id"]
        output += " - " + subscription["attributes"]["certificate_authority"]
        output += " - " + subscription["attributes"]["state"]
        say(output)
      end
    end

    desc "challenges", "Print challenges available for a domain's verification."
    def challenges(domain)
      abort "Must specify valid domain name" unless domain =~ DomainRegex

      domains = FastlyCTL::Fetcher.api_request(:get,"/tls/domains?include=tls_subscriptions.tls_authorizations", {
        use_vnd: true
      })

      tls_authorizations = FastlyCTL::Utils.filter_vnd(domains["included"],"tls_authorization")

      tls_authorizations.each do |tls_authorization|
        tls_authorization["attributes"]["challenges"].each do |challenge|
          if challenge["record_name"] == domain
            FastlyCTL::TLSUtils.print_challenges(tls_authorization)
            abort
          end
        end
      end

      say("#{domain} not found in domain list.")
    end

    desc "delete", "Delete a Fastly Managed TLS Subscription"
    def delete(domain)
      abort "Must specify valid domain name" unless domain =~ DomainRegex

      activation = FastlyCTL::Fetcher.api_request(:get,"/tls/activations?filter[tls_domain.id]=#{domain}", {use_vnd: true})

      if activation["data"].length >= 1
        say("TLS is currently active for #{domain}. If you proceed, Fastly will no longer be able to serve TLS requests to clients for #{domain}.")
        answer = ask("Please type the name of the domain to confirm deactivation and deletion of the Fastly Managed TLS subscription: ")
        abort "Supplied domain does not match the domain requested for deletion--aborting." unless answer == domain

        FastlyCTL::Fetcher.api_request(:delete,"/tls/activations/#{activation["data"][0]["id"]}",{use_vnd:true})
      end

      subscriptions = FastlyCTL::Fetcher.api_request(:get,"/tls/subscriptions", {
        use_vnd: true
      })

      subscriptions["data"].each do |subscription|
        next unless subscription["relationships"]["tls_domains"]["data"][0]["id"] == domain 
        
        FastlyCTL::Fetcher.api_request(:delete,"/tls/subscriptions/#{subscription["id"]}",{use_vnd:true})
        
        say("TLS Subscription for #{domain} has been deleted.")
        abort
      end

      say("No TLS Subscription found for #{domain}...")
    end
  end

  class TLSSubCmd < SubCommandBase
    SubcommandPrefix = "tls"
    desc "managed SUBCOMMAND ...ARGS", "Interface with Fastly Managed TLS Subscriptions (lets-encrypt)"
    subcommand "managed", TLSManagedSubCmd
  end
end
