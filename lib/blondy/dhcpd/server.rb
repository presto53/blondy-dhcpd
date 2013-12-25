require 'net-dhcp'
require 'eventmachine'
require 'socket'

module Blondy
  module DHCPD
    class Server < EM::Connection
      def receive_data(data)
	ip, port = Socket.unpack_sockaddr_in(get_peername)
	dispatcher = Dispatcher.new
	dispatcher.dispatch(data, ip, port)
	dispatcher.callback { |reply| send_datagram(reply.data, reply.ipaddr, reply.port) }
	dispatcher.errback { |message| puts message }
      end
    end
  end
end
