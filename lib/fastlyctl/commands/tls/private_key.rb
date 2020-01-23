module FastlyCTL
  class TLSPrivateKeySubCmd < SubCommandBase
    SubcommandPrefix = "tls privatekey"

    desc "upload <key_name> <path_to_key>", "Upload a private key to Fastly which will be used in conjunction with certificates you upload"
    method_option :pass, :aliases => ["--p"]
    def upload(key_name, path_to_key)
      abort "Key file does not exist" unless File.exists?(path_to_key)
      abort "Key file is not readable" unless File.readable?(path_to_key)

      key_data = File.read(path_to_key)

      begin
        if options.key?(:pass)
          key_data = OpenSSL::PKey.read(key_data,options[:pass])
        else
          key_data = OpenSSL::PKey.read(key_data)
        end
      rescue OpenSSL::PKey::PKeyError
        abort "Unable to parse valid private key from the file provided"
      end

      key_data = key_data.to_pem

      payload = {
        data: {
          type: "tls_private_key",
          attributes: {
            key: key_data,
            name: key_name
          }
        }
      }

      pkey = FastlyCTL::Fetcher.api_request(:post,"/tls/private_keys", {
        body: payload.to_json,
        use_vnd: true
      })

      say("Private key #{key_name} has been uploaded successfully. You may now upload certificates signed with this key.")
    end

    desc "list", "List all private keys"
    def list
      pkeys = FastlyCTL::Fetcher.api_request(:get,"/tls/private_keys", {
        use_vnd: true
      })

      if pkeys["data"].length == 0
        say("No private keys found.")
        abort
      end

      pkeys["data"].each do |pkey|
        attributes = pkey["attributes"]
        say("[#{pkey["id"]}] #{attributes["name"]} (#{attributes["key_type"]} #{attributes["key_length"]}) - #{attributes["replace"] ? "DUE" : "NOT due"} for rotation")
      end
    end
  end
end
