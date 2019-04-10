module FastlyCTL
  class CLI < Thor
    desc "diff", "Diff two service versions. By default, diffs the active version of the service assumed from the current directory with the local VCL in the current directory. Options allow you to specify different versions and different services."
    method_option :version1, :aliases => ["--v1"]
    method_option :version2, :aliases => ["--v2"]
    method_option :service1, :aliases => ["--s1"]
    method_option :service2, :aliases => ["--s2"]
    method_option :generated, :aliases => ["--g"]
    def diff
      if options[:service1]
        service1 = options[:service1]
      else
        service1 = FastlyCTL::Utils.parse_directory
        abort "Could not parse service id from directory" unless service1
      end
      if options[:service2]
        service2 = options[:service2]
      else
        service2 = FastlyCTL::Utils.parse_directory

        # use service1 for both if unspecified
        service2 = service1 unless service2
      end

      # diffing different services - no references to local vcl here
      if service1 != service2
        version1 = options.key?(:version1) ? options[:version1] : FastlyCTL::Fetcher.get_active_version(service1)
        version2 = options.key?(:version2) ? options[:version2] : FastlyCTL::Fetcher.get_active_version(service2)
      end

      # diffing the same service
      if service1 == service2
        # if both are specified, diff them
        if options[:version1] && options[:version2]
          version1 = options[:version1]
          version2 = options[:version2]
        end
        # if version1 is not specified, diff local with version 2
        if !options[:version1] && options[:version2]
          version1 = false
          version2 = options[:version2]
        end
        # if version2 is not specified, diff local with version 1
        if options[:version1] && !options[:version2]
          version1 = options[:version1]
          version2 = false
        end
        if !options[:version1] && !options[:version2]
          # if neither are specified, diff local with active version
          version1 = FastlyCTL::Fetcher.get_active_version(service2)
          version2 = false
        end
      end

      say("Diffing#{options[:generated] ? " generated VCL for" : ""} #{service1} #{version1 ? "version "+version1.to_s : "local VCL"} with #{service2} #{version2 ? "version "+version2.to_s : "local VCL"}.")

      if version1
        v1_vcls = FastlyCTL::Fetcher.get_vcl(service1, version1,options[:generated])
      else
        abort "Cannot diff generated VCL with local VCL" if options[:generated]
        Dir.foreach(Dir.pwd) do |p|
          next unless File.file?(p)
          next unless p =~ /\.vcl$/

          v1_vcls ||= Array.new
          v1_vcls << {
            "name" => p.chomp(".vcl"),
            "content" => File.read(p)
          }
        end
      end

      if version2
        v2_vcls = FastlyCTL::Fetcher.get_vcl(service2, version2,options[:generated])
      else
        abort "Cannot diff generated VCL with local VCL" if options[:generated]
        Dir.foreach(Dir.pwd) do |p|
          next unless File.file?(p)
          next unless p =~ /\.vcl$/

          v2_vcls ||= Array.new
          v2_vcls << {
            "name" => p.chomp(".vcl"),
            "content" => File.read(p)
          }
        end
      end

      if options[:generated]
        say(FastlyCTL::Utils.diff_generated(v1_vcls,v2_vcls))
      else
        say(FastlyCTL::Utils.diff_versions(v1_vcls,v2_vcls))
      end

    end
  end
end
