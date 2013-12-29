require 'eventmachine'
require_relative 'dhcpd/server'
require_relative 'dhcpd/logger'

EM.run do
  EM.open_datagram_socket('0.0.0.0', 67, Blondy::DHCPD::Server)
end
