module BigQuery

    def BigQuery.parse_secret_key(file)
        key = File.read(file)
        if key[0..26] != "-----BEGIN PRIVATE KEY-----"
            abort "Error, private key file should begin with -----BEGIN PRIVATE KEY-----"
        end

        return key 
    end

    def BigQuery.ensure_opts(required_opts,options) 
        required_opts.each { |k| 
            if !options.key?(k)
                abort "Error, option #{k.to_s} is required for this action"
            end
        }
    end

    def BigQuery.print_configs(config)
        max = {}
        max["name"] = 0 
        max["dataset"] = 0 
        max["table"] = 0 
        max["project_id"] = 0 
        fields = ["name","dataset","table","project_id"]

        config.each { |c| 
            fields.each { |f| 
                max[f] = c[f].length > max[f] ? c[f].length : max[f]
           }
        }
        
        puts
        puts "Name".ljust(max["name"]) + " | " + "Dataset".ljust(max["dataset"]) + " | " + "Table".ljust(max["table"]) + " | " + "ProjectId".ljust(max["project_id"])
        puts "-" * (max["name"] + max["dataset"] + max["table"] + max["project_id"])
        config.each { |c| 
            puts "%s | %s | %s | %s" % [c["name"].ljust(max["name"]), c["dataset"].ljust(max["dataset"]), c["table"].ljust(max["table"]), c["project_id"].ljust(max["project_id"])]
        }
        puts
    end


    def self.create(options)
        puts "Creating bigquery log endpoint"
        required_opts = ["name", "format_file", "user", "secret_key_file", "project_id", "dataset", "table" ]
        
        ensure_opts(required_opts,options)

        parsed_key = parse_secret_key(options[:secret_key_file])

        parsed_format = File.read(options[:format_file])

        params = {}

        id  = options[:service]
        version = FastlyCTL::Fetcher.get_writable_version(id) unless options[:version]
        version ||= options[:version]

        params[:name] = options[:name] 
        params[:format] = parsed_format 
        params[:format_version] = options[:format_version] unless options[:format_version].nil?
        params[:user] = options[:user]
        params[:secret_key] = parsed_key
        params[:project_id] = options[:project_id]
        params[:dataset] = options[:dataset]
        params[:table] = options[:table]
        params[:template_suffix] = options[:template_suffix] unless options[:template_suffix].nil?
        params[:placement] = options[:placement] unless options[:placement].nil?
        params[:response_condition] = options[:response_condition] unless options[:response_condition].nil?

        FastlyCTL::Fetcher.api_request(:post, "/service/#{id}/version/#{version}/logging/bigquery", body: params)
        puts "BigQuery logging provider created in service id #{id} on version #{version}"
    end

    def self.update(options)
        required_opts = ["name"]
        ensure_opts(required_opts,options)
        
        puts "Updating bigquery log endpoint #{options[:name]}"

        parsed_key = parse_secret_key(options[:secret_key_file]) unless options[:secret_key_file].nil?
        parsed_format = File.read(options[:format_file]) unless options[:format_file].nil?

        params = {}

        id  = options[:service]
        version = FastlyCTL::Fetcher.get_writable_version(id) unless options[:version]
        version ||= options[:version]

        params[:name] = options[:new_name] unless options[:new_name].nil? 
        params[:format] = parsed_format unless options[:format_file].nil?
        params[:format_version] = options[:format_version] unless options[:format_version].nil?
        params[:user] = options[:user] unless options[:user].nil?
        params[:secret_key] = parsed_key  unless options[:secret_key_file].nil?
        params[:project_id] = options[:project_id] unless options[:project_id].nil?
        params[:dataset] = options[:dataset] unless options[:dataset].nil?
        params[:table] = options[:table] unless options[:table].nil?
        params[:template_suffix] = options[:template_suffix] unless options[:template_suffix].nil?
        params[:placement] = options[:placement] unless options[:placement].nil?
        params[:response_condition] = options[:response_condition] unless options[:response_condition].nil?

        FastlyCTL::Fetcher.api_request(:put, "/service/#{id}/version/#{version}/logging/bigquery/#{options[:name]}", body: params)
        puts "BigQuery logging provider update in service id #{id} on version #{version}"
    end

    def self.list(options)
        id = options[:service]
        version = FastlyCTL::Fetcher.get_writable_version(id) unless options[:version]
        version ||= options[:version]

        puts "Listing all BigQuery configurations for service #{id} version #{version}"

        configs = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/logging/bigquery")
        print_configs(configs) 
    end

    def self.show(options)
        required_opts = ["name"]
        ensure_opts(required_opts,options)
        id  = options[:service]
        version = FastlyCTL::Fetcher.get_writable_version(id) unless options[:version]
        version ||= options[:version]

        resp = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/logging/bigquery/#{options[:name]}")
        puts JSON.pretty_generate(resp)
    end

    def self.delete(options)
        required_opts = ["version","name"]
        ensure_opts(required_opts,options)

        id  = options[:service]
        version = FastlyCTL::Fetcher.get_writable_version(id) unless options[:version]
        version ||= options[:version]

        resp = FastlyCTL::Fetcher.api_request(:delete, "/service/#{id}/version/#{version}/logging/bigquery/#{options[:name]}")
        puts JSON.pretty_generate(resp)
    end

end