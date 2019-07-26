require "fastlyctl/commands/purge_all"
require "fastlyctl/commands/open"
require "fastlyctl/commands/download"
require "fastlyctl/commands/diff"
require "fastlyctl/commands/upload"
require "fastlyctl/commands/activate"
require "fastlyctl/commands/skeleton"
require "fastlyctl/commands/clone"
require "fastlyctl/commands/create_service"
require "fastlyctl/commands/dictionary"
require "fastlyctl/commands/login"
require "fastlyctl/commands/watch"
require "fastlyctl/commands/token"
require "fastlyctl/commands/domain"
require "fastlyctl/commands/snippet"
require "fastlyctl/commands/acl"
require "fastlyctl/commands/copy"
require "fastlyctl/commands/logging"


module FastlyCTL
  class CLI < Thor
    class_option :debug, :desc => 'Enabled debug mode output'

    def initialize(a,b,c)
      unless File.exist?(FastlyCTL::TOKEN_FILE)
        if yes?("Unable to locate API token. Would you like to login first?")
          self.login
        end
      end

      super

      if options.key?(:debug)
        Typhoeus::Config.verbose = true
      end
    end

    desc "version", "Displays version of the VCL gem."
    def version
      say("VCL gem version is #{FastlyCTL::VERSION}")
    end
  end
end
