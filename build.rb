require_relative 'lib/fastlyctl/version.rb'

system("gem build fastlyctl.gemspec && gem install ./fastlyctl-#{FastlyCTL::VERSION}.gem && gem cleanup fastlyctl")
