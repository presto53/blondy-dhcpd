# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blondy/dhcpd/version'

Gem::Specification.new do |spec|
  spec.name          = "blondy-dhcpd"
  spec.version       = Blondy::Dhcpd::VERSION
  spec.authors       = ["Pavel Novitskiy"]
  spec.email         = ["altusensix@gmail.com"]
  spec.description   = %q{DHCPd with remote pool configurations obtained via HTTP API from blondy-server}
  spec.summary       = %q{DHCPd with remote pools}
  spec.homepage      = "https://github.com/presto53/blondy-dhcpd"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.0"
  spec.add_development_dependency "simplecov"

  spec.add_runtime_dependency 'eventmachine', '>= 0.12.0'
  spec.add_runtime_dependency 'net-dhcp', '>= 1.1.1'
  spec.add_runtime_dependency 'log4r'
end
