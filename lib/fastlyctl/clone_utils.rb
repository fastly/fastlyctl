module FastlyCTL
  module CloneUtils
    OBJECT_TYPES = {
      "condition" => {},
      "acl" => {child: "entry", include_version: false},
      "healthcheck" => {},
      "cache_settings" => {},
      "backend" => {},
      "director" => {},
      "dictionary" => {child: "item", include_version: false},
      "gzip" => {},
      "header" => {},
      "request_settings" => {},
      "response_object" => {},
      "settings" => {method: :put},
      "vcl" => {},
      "snippet" => {},
      "logging/s3" => {},
      "logging/s3canary" => {},
      "logging/azureblob" => {},
      "logging/cloudfiles" => {},
      "logging/digitalocean" => {},
      "logging/ftp" => {},
      "logging/bigquery" => {},
      "logging/gcs" => {},
      "logging/honeycomb" => {},
      "logging/logshuttle" => {},
      "logging/logentries" => {},
      "logging/loggly" => {},
      "logging/heroku" => {},
      "logging/openstack" => {},
      "logging/papertrail" => {},
      "logging/scalyr" => {},
      "logging/splunk" => {},
      "logging/sumologic" => {},
      "logging/syslog" => {}
    }

    def self.copy(obj,type,sid,version)
      meta = FastlyCTL::CloneUtils::OBJECT_TYPES[type]
      meta ||= {}

      abort "No service ID on object" unless obj.key?("service_id")
      source_sid = obj["service_id"]
      abort "No version on object" unless obj.key?("version")
      source_version = obj["version"]

      if type == "director"
        backends = obj["backends"].dup
      end

      if type == "snippet" && obj["dynamic"] == "1"
        obj.merge!(FastlyCTL::Fetcher.api_request(:get, "/service/#{source_sid}/snippet/#{obj["id"]}"))
      end

      obj_id = obj["id"]
      obj = FastlyCTL::CloneUtils.filter(type,obj)

      obj = FastlyCTL::Fetcher.api_request(meta.key?(:method) ? meta[:method] : :post, "/service/#{sid}/version/#{version}/#{type}", body: obj )

      if type == "director"
        backends.each do |b|
          FastlyCTL::Fetcher.api_request(:post, "/service/#{sid}/version/#{version}/director/#{obj["name"]}/backend/#{b}", body: obj )
        end
      end

      return obj unless meta.key?(:child)
      new_obj_id = obj["id"] 
      child = meta[:child]

      path = FastlyCTL::CloneUtils.construct_path(source_sid,source_version,meta[:include_version])

      items = []
      entries = []
      FastlyCTL::Fetcher.api_request(:get, "#{path}/#{type}/#{obj_id}/#{FastlyCTL::CloneUtils.pluralize(child)}").each do |child_obj|
        case child
        when "item"
          items.push({
            "op" => "create","item_key" => child_obj["item_key"],"item_value" => child_obj["item_value"]
          })
          next
        when "entry"
          entries.push({
            "op" => "create","ip" => child_obj["ip"],"subnet" => child_obj["subnet"]
          })
          next
        end

        child_obj = FastlyCTL::CloneUtils.filter(type,child_obj)

        path = FastlyCTL::CloneUtils.construct_path(sid,version,meta[:include_version])

        FastlyCTL::Fetcher.api_request(:post, "#{path}/#{type}/#{new_obj_id}/#{child}", body: child_obj )
      end

      FastlyCTL::Fetcher.api_request(:patch, "/service/#{sid}/dictionary/#{new_obj_id}/items", body: {"items" => items}.to_json, headers: {"Content-Type" => "application/json"} ) if items.length > 0
      FastlyCTL::Fetcher.api_request(:patch, "/service/#{sid}/acl/#{new_obj_id}/entries", body: {"entries" => entries}.to_json, headers: {"Content-Type" => "application/json"} ) if entries.length > 0

      return obj
    end

    def self.filter(type,obj)
      filter_keys = ["version","id","service_id","created_at","updated_at","deleted_at","locked"]

      obj.delete_if { |key, value| filter_keys.include?(key) }
      obj.delete_if { |key, value| value.nil? }

      case type
      when "backend"
        obj.delete("ipv4")
        obj.delete("hostname")
        obj.delete("ipv6")
      when "director"
        obj.delete("backends")
      when "snippet"
        obj.delete("snippet_id")
      when "settings"
        # this is to account for a bug in the API which disallows even setting this to zero
        obj.delete("general.default_pci") if obj["general.default_pci"] == 0
      end 

      return obj
    end

    def self.construct_path(id,version,include_version)
      if include_version != false
        path = "/service/#{id}/version/#{version}"
      else
        path = "/service/#{id}"
      end

      return path
    end

    def self.unpluralize(type)
      type = type.dup
      type.sub!(/ies/,"y")
      type.sub!(/s$/,"")
      return type
    end

    def self.pluralize(type)
      type = type.dup
      type += "s" unless type[-1] == "s"
      type.sub!(/ys$/,"ies")
      return type
    end
  end
end
