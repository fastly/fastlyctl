require "fastlyctl/commands/logging/bigquery"

module FastlyCTL
    class LoggingSubCmd < Thor 
      namespace :logging

      desc "bigquery <action>", "Setup BigQuery As a logging provider, available actions are create, update, delete, list and show"
      method_option :service, :aliases => ["--s","--service"], :banner => "Service ID to use", :required => true 
      method_option :version, :aliases => ["--v", "--version"], :banner => "Version of the service to use"
      method_option :name, :aliases => ["--n", "--name"], :banner => "Current name of the logging configuration"
      method_option :new_name, :aliases => ["--nn","--new-name"], :banner => "Used for the update method to rename a configuration"
      method_option :format_file,  :aliases => ["--ff","--format-file"], :banner => "File containing the JSON Representation of the logline, must match BigQuery schema"
      method_option :format_version, :aliases => ["--fv","--format-version"], :banner => "Version of customer format, either 1 or 2, defaults to 2"
      method_option :user, :aliases => ["--u","--user"], :banner => "Google Cloud Service Account Email"
      method_option :secret_key_file, :aliases => ["--scf", "--secret-key-file"],:banner => "Google Cloud Account secret key"
      method_option :project_id, :aliases => ["--p","--project-id"], :banner => "Google Cloud Project ID"
      method_option :dataset, :aliases => ["--d","--dataset"], :banner => "BigQuery Dataset"
      method_option :table, :aliases => ["--t","--table"], :banner => "BigQuery Table"
      method_option :template_suffix, :aliases => ["--ts","--template-suffix"], :banner => "Optional table name suffix"
      method_option :placement, :aliases => ["--pl","--placement"], :banner => "Placement of the logging  call, can be none or waf_debug.  Not required and no default"
      method_option :response_condition, :aliases => ["--r","--response-condition"], :banner => "When to execute, if empty it is always"

      def bigquery(action)
        case action 
        when "create"
          BigQuery.create(options)
        when "list"
          BigQuery.list(options)
        when "update"
          BigQuery.update(options)
        when "show"
          BigQuery.show(options)
        else
          abort "Sorry, invalid action #{action} supplied, only create, update, delete and show are valid."
        end

      end

      # Placeholder for future S3 work 
      # desc "s3 <action>", "Setup S3  as a logging provider"
      # method_option :format, :required => true
      # method_option :keyfile, :required => true
      # method_option :email , :required => true

      # def s3(action)
      #   puts "S3: #{action}"
      # end

      desc "status", "Check the last output of the logging status"
      method_option :service, :aliases => ["--s","--service"], :banner => "Service ID to use", :required => true 

      def status
        id = options[:service]
        resp = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/logging_status")      
        say(JSON.pretty_generate(resp))
      end

    end

    class CLI < Thor
      desc "logging SUBCOMMAND ...ARGS", "Interface with Fastly Logging"
      subcommand "logging", LoggingSubCmd
    end

end