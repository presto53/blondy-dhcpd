require 'net-dhcp'
require 'eventmachine'
require 'socket'

module Blondy
  module DHCPD
    class Server < EM::Connection
      def receive_data(data)
	ip, port = Socket.unpack_sockaddr_in(get_peername)
	action = proc { Dispatcher.dispatch(data, ip, port) }
	callback = proc { |reply| send_datagram(reply.data.pack, reply.ip, reply.port) if reply }
	EM.defer(action,callback)
      end
    end
  end
end
