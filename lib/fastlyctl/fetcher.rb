module FastlyCTL
  module Fetcher
    def self.api_request(method, path, options={})
      options[:endpoint] ||= :api
      options[:params] ||= {}
      options[:headers] ||= {}
      options[:body] ||= nil
      options[:disable_token] ||= false
      options[:expected_responses] ||= [200]
      options[:use_vnd] ||= false

      headers = {"Accept" => "application/json", "Connection" => "close", "User-Agent" => "FastlyCTL: https://github.com/fastly/fastlyctl"}

      if options[:endpoint] == :app
        headers["Referer"] = FastlyCTL::FASTLY_APP
        headers["Fastly-API-Request"] = "true"
      end

      if FastlyCTL::Token && !options[:disable_token]
        headers["Fastly-Key"] = FastlyCTL::Token
      end

      headers["Content-Type"] = "application/x-www-form-urlencoded" if (method == :post || method == :put)

      if options[:use_vnd]
        headers["Accept"] = "application/vnd.api+json"

        if (method == :post || method == :put)
          headers["Content-Type"] = "application/vnd.api+json"
        end
        options[:expected_responses].push(*[201,202,203,204])
      end

      headers.merge!(options[:headers]) if options[:headers].count > 0

      # dont allow header splitting on anything
      headers.each do |k,v|
        headers[k] = v.gsub(/\r|\n/,'')
      end

      url = "#{options[:endpoint] == :api ? FastlyCTL::FASTLY_API : FastlyCTL::FASTLY_RT_API}#{path}"

      response = Typhoeus::Request.new(
        url,
        method: method,
        params: options[:params],
        headers: headers,
        body: options[:body]
      ).run

      if !options[:expected_responses].include?(response.response_code)
        case response.response_code
        when 400
          error = "400: Bad API request--something was wrong with the request made by FastlyCTL."
        when 403
          error = "403: Access Denied by API. Run login command to authenticate."
        when 404
          error = "404: Service does not exist or bad path requested."
        when 503
          error = "503: Error from Fastly API--see details below."
        when 0
          error = "0: Network connection error occurred."
        else
          error = "API responded with status #{response.response_code}."
        end

        error += " Method: #{method.to_s.upcase}, Path: #{path}\n"

        if (options[:use_vnd]) 
          begin
            error_resp = JSON.parse(response.response_body)
          rescue JSON::ParserError
            error_resp = {"errors" => [{"title" => "Error parsing response JSON","details" => "No further information available. Please file a github issue at https://github.com/fastly/fastlyctl"}]}
          end

          error_resp["errors"].each do |e|
            next unless e.key?("title") && e.key?("detail")
            error += e["title"] + " --- " + e["detail"] + "\n"
          end
        else
          error += "Message from API: #{response.response_body}"
        end

        abort error
      end

      return response.response_body unless (response.headers["Content-Type"] =~ /json$/)

      if response.response_body.length > 1
        begin
          return JSON.parse(response.response_body)
        rescue JSON::ParserError
          abort "Failed to parse JSON response from Fastly API"
        end
      else
        return {}
      end
    end

    def self.domain_to_service_id(domain)
      response = Typhoeus::Request.new(FastlyCTL::FASTLY_APP, method:"FASTLYSERVICEMATCH", headers: { :host => domain}).run

      abort "Failed to fetch Fastly service ID or service ID does not exist" if response.response_code != 204

      abort "Fastly response did not contain service ID" unless response.headers["Fastly-Service-Id"]

      return response.headers["Fastly-Service-Id"]
    end

    def self.get_active_version(id)
      service = self.api_request(:get, "/service/#{id}")

      max = 1

      service["versions"].each do |v|
        if v["active"] == true
          return v["number"]
        end

        max = v["number"] if v["number"] > max
      end

      return max
    end

    def self.get_writable_version(id)
      service = self.api_request(:get, "/service/#{id}")

      active = false
      version = false
      max = 1
      service["versions"].each do |v|
        if v["active"] == true
          active = v["number"].to_i
        end

        if active && v["number"].to_i > active && v["locked"] == false
          version = v["number"]
        end

        max = version if version && version > max
      end

      return max unless active

      version = self.api_request(:put, "/service/#{id}/version/#{active}/clone")["number"] unless version

      return version
    end
    
    def self.get_service_version(id, readonly=false)
      if readonly
        return self.get_active_version(id)
      end
      
      return self.get_writable_version(id)
    end

    def self.get_vcl(id, version, generated=false)
      if generated
        vcl = self.api_request(:get, "/service/#{id}/version/#{version}/generated_vcl")
      else
        vcl = self.api_request(:get, "/service/#{id}/version/#{version}/vcl?include_content=1")
      end

      if vcl.length == 0
        return false
      else
        return vcl
      end
    end

    def self.get_snippets(id,version)
      snippet = self.api_request(:get, "/service/#{id}/version/#{version}/snippet")

      if snippet.length == 0
        return false
      else
        return snippet
      end
    end

    def self.upload_snippet(service,version,content,name)
      return FastlyCTL::Fetcher.api_request(:put, "/service/#{service}/version/#{version}/snippet/#{FastlyCTL::Utils.percent_encode(name)}", {:endpoint => :api, body: {
          content: content
        }
      })
    end

    def self.upload_vcl(service,version,content,name,is_main=true,is_new=false)
      params = { name: name, main: "#{is_main ? "1" : "0"}", content: content }

      # try to create, if that fails, update
      if is_new
        response = FastlyCTL::Fetcher.api_request(:post, "/service/#{service}/version/#{version}/vcl", {:endpoint => :api, body: params, expected_responses:[200,409]})
        if response["msg"] != "Duplicate record"
          return
        end
      end

      response = FastlyCTL::Fetcher.api_request(:put, "/service/#{service}/version/#{version}/vcl/#{FastlyCTL::Utils.percent_encode(name)}", {:endpoint => :api, body: params, expected_responses: [200,404]})

      # The VCL got deleted so recreate it.
      if response["msg"] == "Record not found"
        FastlyCTL::Fetcher.api_request(:post, "/service/#{service}/version/#{version}/vcl", {:endpoint => :api, body: params})
      end
    end

    def self.create_token(options)
      thor = Thor::Shell::Basic.new

      headers = {}
      resp = FastlyCTL::Fetcher.api_request(:post, "/tokens", {
        disable_token: true,
        endpoint: :api,
        body: options,
        headers: headers,
        expected_responses: [200,400]
      })

      if resp.has_key?("msg") && resp["msg"] == "2fa.verify"
        thor.say("\nTwo factor auth enabled on account, second factor needed.")
        code = thor.ask('Please enter verification code:', echo: false)

        headers = {}
        headers["Fastly-OTP"] = code
        resp = FastlyCTL::Fetcher.api_request(:post, "/tokens", {
          disable_token: true,
          endpoint: :api,
          body: options,
          headers: headers
        })
      elsif resp.has_key?("msg")
        abort "ERROR: #{resp}"
      end

      thor.say("\n#{resp["id"]} created.")

      return resp
    end
  end
end