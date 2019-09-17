module FastlyCTL
    class CLI < Thor
      desc "condition ACTION NAME", "Manipulate conditions on a service. Available actions are create, delete, update, show and list. NAME parameter not required for list ACTION"
      method_option :service, :aliases => ["--s"]
      method_option :version, :aliases => ["--v"]
      method_option :type, :aliases => ["--t"]
      method_option :yes, :aliases => ["--y"]
      method_option :priority, :aliases => ["--p"]
      method_option :statement, :aliases => ["--st"]
      method_option :comment, :aliases => ["--c"]
      method_option :new_name, :aliases => ["--nn"]  #used to rename condition in update
  
      def self.print_condition_header
        puts
        puts "Name".ljust(40) + " | " + "Priority".ljust(8) + " | " + "Type".ljust(10) + " | " + "Statement".ljust(20) 
        puts "-------------------------------------------------------------------------------------------------------"        
      end

      def self.print_conditions(conditions)
        self.print_condition_header

        conditions.each { |c| 
          puts "%s | %s | %s | %s " % [c["name"].ljust(40), c["priority"].ljust(8), c["type"].ljust(10), c["statement"].ljust(20)]
        }
      end

      def condition(action,name=false)
        id = FastlyCTL::Utils.parse_directory unless options[:service]
        id ||= options[:service]

        abort "Could not parse service id from directory. Use --s <service> to specify, vcl download, then try again." unless id

        version = FastlyCTL::Fetcher.get_writable_version(id) unless options[:version]
        version ||= options[:version].to_i

        encoded_name = URI.escape(name) if name

        case action 
            when "list"
                conditions =  FastlyCTL::Fetcher.api_request(:get,"/service/#{id}/version/#{version}/condition")
                CLI.print_conditions(conditions)

            when "create"
                abort "Must supply a condition name as second parameter" unless name
                abort "Must supply a statement to create a condition" unless options[:statement]

                params = {}
                params[:name] = name 
                params[:statement] = options[:statement]

                params[:priority] = options[:priority] if options.key?(:priority)
                params[:type] = options[:type] if options.key?(:type)
                params[:comment] = options[:comment] if options.key?(:comment) 

                FastlyCTL::Fetcher.api_request(:post,"/service/#{id}/version/#{version}/condition",{
                    params: params
                })
                say("Condition #{name} created on #{id} version #{version}")

            when "update"
                abort "Must supply a condition name as second parameter" unless name

                params = {}
                params[:name] = options[:new_name] if options.key?(:new_name) 
                params[:statement] = options[:statement] if options.key?(:statement)

                params[:priority] = options[:priority] if options.key?(:priority)
                params[:type] = options[:type] if options.key?(:type)
                params[:comment] = options[:comment] if options.key?(:comment) 

                FastlyCTL::Fetcher.api_request(:put,"/service/#{id}/version/#{version}/condition/#{encoded_name}",{
                    params: params
                })
                say("Condition #{name} updated on #{id} version #{version}")    

            when "show"
                abort "Must supply a condition name as second parameter" unless name

                c =  FastlyCTL::Fetcher.api_request(:get,"/service/#{id}/version/#{version}/condition/#{encoded_name}")

                CLI.print_conditions([c])
                
            when "delete"
                abort "Must supply a condition name as second parameter" unless name

                c =  FastlyCTL::Fetcher.api_request(:delete,"/service/#{id}/version/#{version}/condition/#{encoded_name}")
                say("Condition #{name} deleted on #{id} version #{version}")
               
        end
      end

    end
end