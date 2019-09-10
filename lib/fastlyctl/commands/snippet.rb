module FastlyCTL
  class CLI < Thor
    desc "snippet ACTION NAME", "Manipulate snippets on a service. Available actions are create, delete, and list. Use upload command to update snippets."
    method_option :service, :aliases => ["--s"]
    method_option :version, :aliases => ["--v"]
    method_option :type, :aliases => ["--t"]
    method_option :dynamic, :aliases => ["--d"]
    method_option :yes, :aliases => ["--y"]
    method_option :priority, :aliases => ["--p"]
    method_option :filename, :aliases => ["--f"] 

    def snippet(action,name=false)
      id = FastlyCTL::Utils.parse_directory unless options[:service]
      id ||= options[:service]

      abort "Could not parse service id from directory. Use --s <service> to specify, vcl download, then try again." unless id

      version = FastlyCTL::Fetcher.get_writable_version(id) unless options[:version]
      version ||= options[:version].to_i

      encoded_name = URI.escape(name) if name

      filename = options.key?(:filename) ? options[:filename] : "#{name}.snippet"
      puts "Filename: " + filename

      case action
      when "upload"
        abort "Must supply a snippet name as second parameter" unless name

        abort "No snippet file for #{name} found locally" unless File.exists?(filename)

        active_version = FastlyCTL::Fetcher.get_active_version(id)

        snippets = FastlyCTL::Fetcher.get_snippets(id, active_version)

        abort "No snippets found in active version" unless snippets.is_a?(Array) && snippets.length > 0

        snippet = false
        snippets.each do |s|
          if s["name"] == name
            abort "This command is for dynamic snippets only. Use vcl upload for versioned snippets" if s["dynamic"] == "0"

            snippet = s
          end
        end

        abort "No snippet named #{name} found on active version" unless snippet

        # get the snippet from the dynamic snippet api endpoint so you have the updated content
        snippet = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/snippet/#{snippet["id"]}")

        new_content = File.read(filename)
        priority = options.key(:priority) ? options[:priority] : snippet[:priority]

        unless options.key?(:yes)
          say(FastlyCTL::Utils.get_diff(snippet["content"],new_content))
          abort unless yes?("Given the above diff between the old dyanmic snippet content and the new content, are you sure you want to upload your changes? REMEMBER, THIS SNIPPET IS VERSIONLESS AND YOUR CHANGES WILL BE LIVE IMMEDIATELY!")
        end

        FastlyCTL::Fetcher.api_request(:put, "/service/#{id}/snippet/#{snippet["snippet_id"]}", {:endpoint => :api, body: {
            content: new_content,
            priority: priority.to_s
          }
        })

        say("New snippet content for #{name} uploaded successfully")
      when "create"
        abort "Must supply a snippet name as second parameter" unless name

        content = "# Put snippet content here."

        FastlyCTL::Fetcher.api_request(:post,"/service/#{id}/version/#{version}/snippet",{
          params: {
            name: name,
            type: options[:type] ? options[:type] : "recv",
            content: content,
            dynamic: options.key?(:dynamic) ? 1 : 0,
            priority: options.key?(:priority) ? options[:priority].to_s : "100"
          }
        })
        say("#{name} created on #{id} version #{version}")

        unless File.exists?(filename)
          File.open(filename, 'w+') {|f| content }
          say("Blank snippet file created locally.")
          return
        end

        if options.key?(:yes) || yes?("Local file #{filename} found. Would you like to upload its content?")
          FastlyCTL::Fetcher.upload_snippet(id,version,File.read(filename),name)
          say("Local snippet file content successfully uploaded.")
        end
      when "delete"
        abort "Must supply a snippet name as second parameter" unless name

        FastlyCTL::Fetcher.api_request(:delete,"/service/#{id}/version/#{version}/snippet/#{encoded_name}")
        say("#{name} deleted on #{id} version #{version}")

        return unless File.exists?(filename)

        if options.key?(:yes) || yes?("Would you like to delete the local file #{name}.snippet associated with this snippet?")
          File.delete(filename)
          say("Local snippet file #{filename} deleted.")
        end
      when "list"
        snippets = FastlyCTL::Fetcher.api_request(:get,"/service/#{id}/version/#{version}/snippet")
        say("Listing all snippets for #{id} version #{version}")
        snippets.each do |d|
          say("#{d["name"]}: Subroutine: #{d["type"]}, Dynamic: #{d["dynamic"]}")
        end
      else
        abort "#{action} is not a valid command"
      end
    end
  end
end
