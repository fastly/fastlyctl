module FastlyCTL
  class CLI < Thor
    desc "watch POP", "Watch live stats on a service. Optionally specify a POP by airport code."
    method_option :service, :aliases => ["--s"]
    def watch(pop=false)
      service = options[:service]
      service ||= FastlyCTL::Utils.parse_directory

      abort "Could not parse service id from directory. Use --s <service> to specify, vcl download, then try again." unless service

      ts = false

      pop = pop.upcase if pop

      while true
        data = FastlyCTL::Fetcher.api_request(:get,"/rt/v1/channel/#{service}/ts/#{ts ? ts : 'h/limit/120'}", :endpoint => :rt)
        
        unless data["Data"].length > 0
          say("No data to display!")
          abort
        end

        if pop
          unless data["Data"][0]["datacenter"].key?(pop)
            abort "Could not locate #{pop} in data feed."
          end
          agg = data["Data"][0]["datacenter"][pop]
        else 
          agg = data["Data"][0]["aggregated"]
        end

        rps = agg["requests"]
        # gbps
        uncacheable = agg["pass"] + agg["synth"] + agg["errors"]
        bw = ((agg["resp_header_bytes"] + agg["resp_body_bytes"]).to_f * 8.0) / 1000000000.0
        shield = agg["shield"] || 0
        hit_rate = (1.0 - ((agg["miss"] - shield).to_f / ((agg["requests"] - uncacheable).to_f))) * 100.0
        passes = agg["pass"]
        miss_time = agg["miss"] > 0 ? ((agg["miss_time"] / agg["miss"]) * 1000).round(0) : 0
        synth = agg["synth"]
        errors = agg["errors"]

        $stdout.flush
        print " #{rps} req/s | #{bw.round(3)}gb/s | #{hit_rate.round(2)}% Hit Ratio | #{passes} passes/s | #{synth} synths/s | #{miss_time}ms miss time | #{errors} errors/s   \r"

        ts = data["Timestamp"]
      end
    end
  end
end
