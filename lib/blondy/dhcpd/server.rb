require 'net-dhcp'
require 'eventmachine'

module Blondy
  module DHCPD
    class Server < EM::Connection
      def receive_data(data)
	Dispatcher.dispatch(data)
      end
    end
  end
end
