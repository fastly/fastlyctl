module FastlyCTL
  class CLI < Thor
    desc "acl ACTION ACL_NAME IP_OR_SUBNET", "Manipulate ACLS.\n  Actions:\n    create: Create an ACL\n
    delete: Delete an ACL\n
    list: Provide a list of ACLs on this service\n
    add: Add an IP/subnet to an ACL\n
    remove: Remove an IP/subnet from an ACL\n
    list_ips: List all IPs/subnets in the ACL\n
    bulk_add: Perform operations on the ACL in bulk. A list of operations in JSON format should be specified in the ip field. Documentation on this format can be found here: https://docs.fastly.com/api/config#acl_entry_c352ca5aee49b7898535cce488e3ba82"
    method_option :service, :aliases => ["--s"]
    method_option :version, :aliases => ["--v"]
    method_option :negate, :aliases => ["--n"]
    def acl(action, name=false, ip=false)
      id = FastlyCTL::Utils.parse_directory unless options[:service]
      id ||= options[:service]

      abort "Could not parse service id from directory. Specify service id with --service or use from within service directory." unless id

      version = FastlyCTL::Fetcher.get_writable_version(id) unless options[:version]
      version ||= options[:version]

      case action
      when "create"
        abort "Must specify name for ACL" unless name
        FastlyCTL::Fetcher.api_request(:post, "/service/#{id}/version/#{version}/acl", params: { name: name })

        say("ACL #{name} created.")
      when "delete"
        abort "Must specify name for ACL" unless name
        FastlyCTL::Fetcher.api_request(:delete, "/service/#{id}/version/#{version}/acl/#{name}")

        say("ACL #{name} deleted.")
      when "list"
        resp = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/acl")

        say("No ACLs on service in this version.") unless resp.length > 0

        resp.each do |d|
          puts "#{d["id"]} - #{d["name"]}"
        end
      when "add"
        abort "Must specify name for ACL" unless name
        abort "Must specify IP" unless ip
        acl = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/acl/#{name}")
        FastlyCTL::Fetcher.api_request(:post, "/service/#{id}/acl/#{acl["id"]}/entry", params: { ip: ip, negated: options.key?(:negate) ? "1" : "0" })   

        say("#{ip} added to ACL #{name}.")   
      when "remove"
        abort "Must specify name for ACL" unless name
        abort "Must specify IP for ACL entry" unless ip
        acl = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/acl/#{name}")
        entries = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/acl/#{acl["id"]}/entries")

        entry = false
        entries.each do |e|
          if e["ip"] == ip
            entry = e
            break
          end
        end

        abort "IP #{ip} not found in ACL" unless entry

        FastlyCTL::Fetcher.api_request(:delete, "/service/#{id}/acl/#{acl["id"]}/entry/#{entry["id"]}")

        say("IP #{ip} removed from ACL #{name}.")
      when "list_ips"
        abort "Must specify name for ACL" unless name
        acl = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/acl/#{name}")
        entries = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/acl/#{acl["id"]}/entries")

        say("No items in ACL.") unless entries.length > 0
        entries.each do |i|
          puts "#{i["ip"]} - Negated: #{i["negated"] == "0" ? "false" : "true"}"
        end
      when "bulk_add"
        abort "Must specify name for ACL" unless name
        abort "Must specify JSON blob of operations in ip field. Documentation on this can be found here: https://docs.fastly.com/api/config#acl_entry_c352ca5aee49b7898535cce488e3ba82" unless ip
        acl = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/acl/#{name}")
        FastlyCTL::Fetcher.api_request(:patch, "/service/#{id}/acl/#{acl["id"]}/items", {body: ip, headers: {"Content-Type" => "application/json"}})

        say("Bulk add operation completed successfully.")
      else
        abort "#{action} is not a valid command"
      end
    end
  end
end
