module FastlyCTL
  class TLSSubCmd < Thor 
    desc "managed <action>", "TBD"
    def managed(action,domain)
      domain_regex = /(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9][a-z0-9-]{0,61}[a-z0-9]/

      case action 
      when "create"
        abort "Must specify valid domain name" unless domain =~ domain_regex

        tls_configs = FastlyCTL::TLSUtils.get_tls_config
        pp tls_configs
        FastlyCTL::TLSUtils.select_tls_config(tls_configs)
        abort

        payload = {
          data: {
            type: "tls_subscription",
            attributes: {
              certificate_authority: "lets-encrypt",
              relationships: {
                tls_domains: {
                  data: [
                    {
                      type: "tls_domain",
                      id: domain
                    }
                  ]
                }
              }
            }
          }
        }

       pp FastlyCTL::Fetcher.api_request(:post,"/tls/subscriptions", {
          body: payload,
          use_vnd: true
        })
      else
        abort "Sorry, invalid action #{action} supplied, only create, update, delete and show are valid."
      end
    end
  end
end
