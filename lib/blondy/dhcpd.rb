require 'eventmachine'
require_relative 'dhcpd/server'

module Blondy
  module DHCPD
    EM.run do
      EM.open_datagram_socket('0.0.0.0', 67, Server)
    end
  end
end
