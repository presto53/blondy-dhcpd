require 'eventmachine'
require 'yaml'
require_relative 'dhcpd/server'
require_relative 'dhcpd/logger'

Blondy::DHCPD::CONFIG = YAML::load(File.open(ENV['BLONDY_CONFIGPATH'] || '/etc/blondy/dhcpd.yml'))

EM.run do
  EM.open_datagram_socket('0.0.0.0', 67, Blondy::DHCPD::Server)
end
