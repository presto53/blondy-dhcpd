require 'net-dhcp'
require 'ostruct'
require 'ipaddr'

module Blondy
  module DHCPD
    class Dispatcher
      class << self
	def dispatch(data, ip, port)
	  @data = DHCP::Message.from_udp_payload(data) rescue raise(IncorrectMessage, 'Incorrect message received.')
	  raise(IncorrectMessage, 'Incorrect message received.') unless @data
	  DHCP::Message.class_eval {attr_accessor :hwaddr}
	  @data.hwaddr = @data.chaddr.take(@data.hlen).map {|x| x.to_s(16).size<2 ? '0'+x.to_s(16) : x.to_s(16)}.join(':')
	  @reply = OpenStruct.new
	  msg_class = @data.class.to_s.gsub(/^.*::/, '').downcase
	  send("#{msg_class}_handler".to_sym)
	  if @reply.data
	    @reply.data.xid = @data.xid if @data.xid && @reply.data
	    @reply
	  else
	    false
	  end
	end

	private

	def discover_handler
	  @pool = Pool.query({hwaddr: @data.hwaddr, type: :discover})
	  if @pool
	    @reply.data = DHCP::Offer.new
	    create_reply
	  else
	    @reply.data = nil
	  end
	end

	def request_handler
	  @pool = Pool.query({hwaddr: @data.hwaddr, type: :request})
	  if @pool
	    @reply.data = DHCP::ACK.new
	    create_reply
	  else
	    @reply.data = nil
	  end
	end

	def release_handler
	  @reply.data = nil
	end

	def inform_handler
	  @reply.data = DHCP::ACK.new
	end

	def create_reply
	  @reply.ip = '255.255.255.255'
	  @reply.port = 68
	  if @data.giaddr == 0 and @data.ciaddr != 0
	    @reply.ip = IPAddr.new(@data.ciaddr, family = Socket::AF_INET).to_s
	  elsif @data.giaddr != 0
	    @reply.ip = IPAddr.new(@data.giaddr, family = Socket::AF_INET).to_s
	    @reply.port = 67
	  else
	    false
	  end
	  @reply.data.yiaddr = IPAddr.new(@pool.data.yiaddr).to_i
	  @reply.data.fname = @pool.data.fname.unpack('C128').map {|x| x ? x : 0}
	  @reply.data.options = @pool.data.options
	  @reply.data.siaddr = IPAddr.new(Blondy::DHCPD::CONFIG[:server_ip]).to_i
	end

	def method_missing(*args)
	  raise NoMessageHandler, 'No appropriate handler for message.'
	end
      end
    end
  end
end

class NoMessageHandler < StandardError
end
class IncorrectMessage < StandardError
end

