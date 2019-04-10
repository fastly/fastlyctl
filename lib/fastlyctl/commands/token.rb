module FastlyCTL
  class CLI < Thor
    desc "token ACTION", "Manipulate API tokens. Available actions are list, create, and delete. Scope defaults to admin:write. Options are --scope and --services. --services should be a comma separated list of services to restrict this token to."
    method_option :customer, :aliases => ["--c"]
    method_option :services, :aliases => ["--s"]
    option :scope
    def token(action)
      case action
      when "list"
        if options[:customer]
          tokens = FastlyCTL::Fetcher.api_request(:get, "/customer/#{options[:customer]}/tokens")
        else
          tokens = FastlyCTL::Fetcher.api_request(:get, "/tokens")
        end
        abort "No tokens to display!" unless tokens.length > 0

        pp tokens

      when "create"
        scope = options[:scope]
        scope ||= "global"

        say("You must login again to create tokens.")

        login_results = FastlyCTL::Fetcher.login

        name = ask("What would you like to name your token?")

        o = {
          user: login_results[:user],
          pass: login_results[:pass],
          code: login_results[:code],
          scope: scope,
          name: name
        }

        o[:services] = options[:services].split(",") if options[:services]

        o[:customer] = options[:customer] if options[:customer]

        resp = FastlyCTL::Fetcher.create_token(o)

      when "delete"
        id = ask("What is the ID of the token you'd like to delete?")

        FastlyCTL::Fetcher.api_request(:delete, "/tokens/#{id}", expected_responses: [204])
        say("Token with id #{id} deleted.")
      else
        abort "#{action} is not a valid command"
      end
    end
  end
end
