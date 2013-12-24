require 'eventmachine'
require_relative 'lib/server'

module Blondy
  module DHCPD
    EM.run do
      EM.open_datagram_socket('0.0.0.0', 67, Dispatcher)
    end
  end
end
