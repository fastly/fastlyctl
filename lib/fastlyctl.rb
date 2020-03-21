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
  COOKIE_JAR = ENV['HOME'] + "/.fastlyctl_cookie_jar"
  TOKEN_FILE = ENV['HOME'] + "/.fastlyctl_token"
  FASTLY_API = "https://api.fastly.com"
  FASTLY_APP = "https://manage.fastly.com"
  TANGO_PATH = "/configure/services/"

  Cookies = File.exist?(FastlyCTL::COOKIE_JAR) ? JSON.parse(File.read(FastlyCTL::COOKIE_JAR)) : {}
  # Don't allow header splitting with the key
  Token = File.exist?(FastlyCTL::TOKEN_FILE) ? File.read(FastlyCTL::TOKEN_FILE) : (ENV['FASTLY_TOKEN'] ? ENV['FASTLY_TOKEN'] : false)
end