require 'net-dhcp'
require 'ostruct'
require 'ipaddr'

module Blondy
  module DHCPD
    class Dispatcher
      def self.dispatch(data, ip, port)
	@data = DHCP::Message.from_udp_payload(data)
	reply = OpenStruct.new
	if @data.kind_of?(DHCP::Discover)
	  if @data.giaddr == 0
	    reply.ip = '255.255.255.255'
	    reply.port = 68
	  else
	    reply.ip = IPAddr.new(@data.giaddr, family = Socket::AF_INET).to_s
	    reply.port = 67
	  end
	  reply.data = DHCP::Offer.new
	end
	reply.data.xid = @data.xid
	reply
      end
    end
  end
end
