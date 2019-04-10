module FastlyCTL
  class CLI < Thor
    desc "upload", "Uploads VCL in the current directory to the service."
    method_option :version, :aliases => ["--v"]
    method_option :comment, :aliases => ["--c"]
    def upload
      id = FastlyCTL::Utils.parse_directory

      abort "Could not parse service id from directory. Use -s <service> to specify, vcl download, then try again." unless id

      vcls = {}
      snippets = {}

      Dir.foreach(Dir.pwd) do |p|
        next unless File.file?(p)
        if p =~ /\.vcl$/
          vcls[p.chomp(".vcl")] = {"content" => File.read(p), "name" => p.chomp(".vcl")}
          next
        end

        if (p =~ /\.snippet$/)
          snippets[p.chomp(".snippet")] = {"content" => File.read(p), "name" => p.chomp(".snippet")}
        end
      end

      writable_version = FastlyCTL::Fetcher.get_writable_version(id) unless options[:version]
      writable_version ||= options[:version].to_i
      active_version = FastlyCTL::Fetcher.get_active_version(id);

      old_vcls = FastlyCTL::Fetcher.get_vcl(id, active_version)
      old_snippets = FastlyCTL::Fetcher.get_snippets(id, active_version)
      old_snippets_writable = FastlyCTL::Fetcher.get_snippets(id, writable_version)

      main_found = false

      old_vcls ||= {}
      old_vcls.each do |v|
        next unless vcls.has_key? v["name"]
        diff = FastlyCTL::Utils.get_diff(v["content"], vcls[v["name"]]["content"])

        vcls[v["name"]]["matched"] = true
        vcls[v["name"]]["new"] = false
        main_found = vcls[v["name"]]["main"] = v["main"] == true ? true : false
        vcls[v["name"]]["diff_length"] = diff.length

        next if diff.length < 2

        say(diff)
      end

      old_snippets ||= {}
      old_snippets.each do |s|
        next unless snippets.has_key? s["name"]
        diff = FastlyCTL::Utils.get_diff(s["content"], snippets[s["name"]]["content"])

        if s["dynamic"] == "1"
          snippets[s["name"]]["skip_because_dynamic"] = true
          next
        end

        snippets[s["name"]]["matched"] = true
        snippets[s["name"]]["diff_length"] = diff.length

        next if diff.length < 2

        say(diff)
      end
      old_snippets_writable ||= {}
      old_snippets_writable.each do |s|
        next unless snippets.has_key? s["name"]
        next if (old_snippets.select {|os| os["name"] == s["name"]}).length > 0

        if s["dynamic"] == "1"
          snippets[s["name"]]["skip_because_dynamic"] = true
          next
        end

        snippets[s["name"]]["matched"] = true
        snippets[s["name"]]["diff_length"] = 3

        say(FastlyCTL::Utils.get_diff("",snippets[s["name"]]["content"]))
      end

      vcls.delete_if do |k,v|
        if v["name"] == "generated"
          next unless yes?("The name of this file is 'generated.vcl'. Please do not upload generated VCL back to a service. Are you sure you want to upload this file?")
        end

        if (v["matched"] == true)
          #dont upload if the file isn't different from the old file
          if (v["diff_length"] > 1)
            false
          else
            true
          end
        elsif yes?("VCL #{v["name"]} does not currently exist on the service, would you like to create it?")
          v["new"] = true
          if !main_found
            v["main"] = true 
            main_found = true
          end
          say(FastlyCTL::Utils.get_diff("", v["content"]))
          false
        else 
          say("Not uploading #{v["name"]}")
          true
        end
      end

      snippets.delete_if do |k,s|
        if (s["matched"] == true)
          #dont upload if the file isn't different from the old file
          if (s["diff_length"] > 1)
            false
          else
            true
          end
        else
          if s.key?("skip_because_dynamic")
            true
          else
            say("Not uploading #{s["name"]} because it does not exist on the service. Use the \"snippet create\" command to create it.")
            true
          end
        end
      end

      abort unless yes?("Given the above diff, are you sure you want to upload your changes?")

      vcls.each do |k,v|
        FastlyCTL::Fetcher.upload_vcl(id, writable_version, v["content"], v["name"], v["main"], v["new"])

        say("#{v["name"]} uploaded to #{id}")
      end

      snippets.each do |k,s|
        FastlyCTL::Fetcher.upload_snippet(id, writable_version, s["content"], s["name"])

        say("#{s["name"]} uploaded to #{id}")
      end

      if options.key?(:comment)
        FastlyCTL::Fetcher.api_request(:put, "/service/#{id}/version/#{writable_version}",{
          params: {comment: options[:comment]}
        })
      end

      validation = FastlyCTL::Fetcher.api_request(:get, "/service/#{id}/version/#{writable_version}/validate")

      abort "Compiler reported the following error with the generated VCL: #{validation["msg"]}" if validation["status"] == "error"

      say("VCL(s) have been uploaded to version #{writable_version} and validated.")
    end
  end
end
