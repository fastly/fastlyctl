module FastlyCTL
  class CLI < Thor
    desc "login", "Logs into the app. Required before doing anything else."
    def login
      if FastlyCTL::Token
        abort unless yes?("You already have an access token, are you sure you want to authenticate again?")
      end

      if yes?("Does your organization use SSO to login to Fastly? If so, type \"yes\" and create a 'global' or 'root' scoped token in your web browser. Copy the token to the file ~/.fastlyctl_token and save it.")
        Launchy.open(FastlyCTL::FASTLY_APP + "/account/personal/tokens/new")
        abort
      end

      say("Proceeding with username/password login...")

      username = ask("Username: ")
      password = ask("Password: ", :echo => false)
      say("")

      if username.include?("@fastly.com") && !username.include?("+")
        scope = "root"
      else
        scope = "global"
      end

      say("Creating #{scope} scope token...")

      o = {
        username: username,
        password: password,
        scope: scope,
        name: "fastlyctl_token"
      }

      resp = FastlyCTL::Fetcher.create_token(o)

      token = resp["access_token"]
      token_id = resp["id"]

      File.open(FastlyCTL::TOKEN_FILE , 'w+') {|f| f.write(token) }
      File.chmod(0600, FastlyCTL::TOKEN_FILE)

      resp = FastlyCTL::Fetcher.api_request(:get, "/tokens", { headers: {"Fastly-Key" => token}})
      abort unless resp.count > 0

      resp.each do |t|
        next unless (t["name"] == "fastlyctl_token" && t["id"] != token_id)

        if yes?("There was already a token created with the name fastlyctl_token. To avoid creating multiple tokens, should it be deleted?")
          FastlyCTL::Fetcher.api_request(:delete, "/tokens/#{t["id"]}", {headers: {"Fastly-Key" => token}, expected_responses: [204]})
          say("Token with id #{t["id"]} deleted.")
        end
      end
    end
  end
end
