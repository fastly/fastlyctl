module FastlyCTL
  class CLI < Thor
    desc "dictionary ACTION DICTIONARY_NAME KEY VALUE", "Manipulate edge dictionaries.\n  Actions:\n    create: Create a dictionary\n
    delete: Delete a dictionary\n
    list: Provide a list of dictionaries on this service\n
    upsert: Update a key in a dictionary if it exists. Add the key if it does not.\n
    remove: Remove a key from a dictionary\n
    list_items: List all keys in the dictionary\n
    sync: Synchronizes a dictionary with a comma separated list of key/value pairs. Will create, delete, or update keys as needed. Separate keys and values with = or :.\n
    bulk_add: Perform operations on the dictionary in bulk. A list of operations in JSON format should be specified in the key field. Documentation on this format can be found here: https://docs.fastly.com/api/config#dictionary_item_dc826ce1255a7c42bc48eb204eed8f7f"
    method_option :service, :aliases => ["--s"]
    method_option :version, :aliases => ["--v"]
    method_option :write_only, :aliases => ["--wo"]
    def dictionary(action, name=false, key=false, value=false)
      id = FastlyCTL::Utils.parse_directory unless options[:service]
      id ||= options[:service]

      abort "Could not parse service id from directory. Specify service id with --service or use from within service directory." unless id

      readonly = ["list", "list_items"]

      version = FastlyCTL::Fetcher.get_service_version(id, readonly.include?(action)) unless options[:version]
      version ||= options[:version]

      encoded_name = FastlyCTL::Utils.percent_encode(name) if name

      case action
      when "create"
        abort "Must specify name for dictionary" unless name

        params = { name: name }
        params[:write_only] = true if options.key?(:write_only)

        FastlyCTL::Fetcher.api_request(:post, "/service/#{id}/version/#{version}/dictionary", params: params)

        say("Dictionary #{name} created.")
      when "delete"
        abort "Must specify name for dictionary" unless name
        FastlyCTL::Fetcher.api_request(:delete, "/service/#{id}/version/#{version}/dictionary/#{encoded_name}")

        say("Dictionary #{name} deleted.")
      when "list"
        resp = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/dictionary")

        say("No dictionaries on service in this version.") unless resp.length > 0

        resp.each do |d|
          puts "#{d["id"]} - #{d["name"]}"
        end
      when "upsert"
        abort "Must specify name for dictionary" unless name
        abort "Must specify key and value for dictionary item" unless (key && value)
        dict = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/dictionary/#{encoded_name}")
        FastlyCTL::Fetcher.api_request(:put, "/service/#{id}/dictionary/#{dict["id"]}/item/#{FastlyCTL::Utils.percent_encode(key)}", params: { item_value: value })   

        say("Dictionary item #{key} set to #{value}.")   
      when "remove"
        abort "Must specify name for dictionary" unless name
        abort "Must specify key for dictionary item" unless key
        dict = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/dictionary/#{encoded_name}")
        FastlyCTL::Fetcher.api_request(:delete, "/service/#{id}/dictionary/#{dict["id"]}/item/#{FastlyCTL::Utils.percent_encode(key)}")

        say("Item #{key} removed from dictionary #{name}.")
      when "list_items"
        abort "Must specify name for dictionary" unless name
        dict = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/dictionary/#{encoded_name}")
        resp = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/dictionary/#{dict["id"]}/items")

        say("No items in dictionary.") unless resp.length > 0
        resp.each do |i|
          puts "#{i["item_key"]} : #{i["item_value"]}"
        end
      when "sync"
        abort "Must specify name for dictionary" unless name
        abort "Must supply comma separated list of keys and values as the \"key\" parameter. " unless key

        pairs = {}
        key.split(',').to_set.to_a.each do |kv|
          kv = kv.split("=") if kv.include?("=")
          kv = kv.split(":") if kv.include?(":")
          abort "Keys and values must be separated by an = or : symbol. Found \"#{kv}\"" unless kv.is_a?(Array)
          pairs[kv[0]] = kv[1]
        end
        item_ids = Hash.new
        bulk = []

        dictionary = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/dictionary/#{encoded_name}")
        items = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/dictionary/#{dictionary["id"]}/items")
        items.each do |item|
          unless pairs.key?(item["item_key"])
            bulk.push({
              "op" => "delete",
              "item_key" => item["item_key"]
            })
            next
          end

          if (pairs[item["item_key"]] != item["item_value"])
            bulk.push({
              "op": "upsert",
              "item_key": item["item_key"],
              "item_value": item["item_value"]
            })
          end

          pairs.delete(item["item_key"])
        end

        pairs.each do |k,v|
          bulk.push({
            "op": "create",
            "item_key": k,
            "item_value": v
          })
        end

        FastlyCTL::Fetcher.api_request(:patch, "/service/#{id}/dictionary/#{dictionary["id"]}/items", {body: {items: bulk}.to_json, headers: {"Content-Type" => "application/json"}})

        say("Sync operation completed successfully with #{bulk.length} operations.")

      when "bulk_add"
        abort "Must specify name for dictionary" unless name
        abort "Must specify JSON blob of operations in key field. Documentation on this can be found here: https://docs.fastly.com/api/config#dictionary_item_dc826ce1255a7c42bc48eb204eed8f7f" unless key
        dict = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/dictionary/#{encoded_name}")
        FastlyCTL::Fetcher.api_request(:patch, "/service/#{id}/dictionary/#{dict["id"]}/items", {body: key, headers: {"Content-Type" => "application/json"}})

        say("Bulk add operation completed successfully.")
      else
        abort "#{action} is not a valid command"
      end
    end
  end
end
