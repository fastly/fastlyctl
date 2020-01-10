# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlyctl/version'

Gem::Specification.new do |spec|
  spec.name          = "fastlyctl"
  spec.version       = FastlyCTL::VERSION
  spec.authors       = ["Stephen Basile"]
  spec.email         = ["stephen@fastly.com"]

  spec.summary       = %q{CLI tool for interacting with the Fastly API}
  spec.description   = %q{This gem provides a CLI for managing Fastly configurations}
  spec.homepage      = "http://www.github.com/fastly/fastlyctl"
  spec.license       = "MIT"

  spec.required_ruby_version = '>= 2.2.0'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org/"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.executables << "fastlyctl"
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "typhoeus", "~> 1.3.1"
  spec.add_runtime_dependency "thor", "~> 0.19.4"
  spec.add_runtime_dependency 'diffy', '~> 3.2.1'
  spec.add_runtime_dependency 'launchy', '~> 2.4.3', '>= 2.4.3'
  spec.add_runtime_dependency 'openssl', '~> 2.1.2', '>= 2.1.2'
end
