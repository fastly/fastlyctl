require "typhoeus"
require "thor"
require "diffy"
require "json"
require "uri"
require "launchy"
require "erb"
require "pp"
require "openssl"

require "fastlyctl/version"
require "fastlyctl/fetcher"
require "fastlyctl/clone_utils"
require "fastlyctl/utils"
require "fastlyctl/subcommand_patch"
require "fastlyctl/cli"

include ERB::Util

module FastlyCTL
  TOKEN_FILE = ENV['HOME'] + "/.fastlyctl_token"
  FASTLY_API = "https://api.fastly.com"
  FASTLY_APP = "https://manage.fastly.com"
  FASTLY_RT_API = "https://rt.fastly.com"
  TANGO_PATH = "/configure/services/"

  # Don't allow header splitting with the key
  Token = File.exist?(FastlyCTL::TOKEN_FILE) ? File.read(FastlyCTL::TOKEN_FILE) : (ENV['FASTLYCLI_TOKEN'] ? ENV['FASTLYCLI_TOKEN'] : false)
end
