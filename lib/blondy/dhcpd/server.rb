require 'net-dhcp'
require 'eventmachine'
require 'socket'
require 'log4r'
require_relative 'dispatcher'

module Blondy
  module DHCPD
    # Main class for handling connections
    class Server < EM::Connection
      def initialize
	@buffer = String.new
	super
      end
      # Fires up Dispatcher and send reply back by callback
      def receive_data(data)
	@buffer.clear if (@buffer.size + data.size) > 1000
	@buffer += data

	if @buffer.unpack('C4Nn2N4C16C192NC*').include?($DHCP_MAGIC)
	  process_message(@buffer.dup)
	  @buffer.clear
	end
      end

      private

      def process_message(buffer)
	ip, port = Socket.unpack_sockaddr_in(get_peername)
	action = proc do
	  begin
	    Dispatcher.dispatch(buffer, ip, port)
	  rescue NoMessageHandler
	    Logger.warn 'No handler for message found. Ignore.'
	    false
	  rescue IncorrectMessage
	    Logger.warn 'Incorrect message received. Ignore.'
	    false
	  end
	end
	callback = proc { |reply| send_datagram(reply.data.pack, reply.ip, reply.port) if reply && reply.data }
	EM.defer(action,callback)
      end
    end
  end
end

class NoMessageHandler < StandardError
end
class IncorrectMessage < StandardError
end
