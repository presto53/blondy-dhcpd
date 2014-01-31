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
	  reply
	end

	private

	def reply
	  DHCP::Message.class_eval {attr_accessor :hwaddr}
	  @data.hwaddr = @data.chaddr.take(@data.hlen).map {|x| x.to_s(16).size<2 ? '0'+x.to_s(16) : x.to_s(16)}.join(':')
	  @reply = OpenStruct.new
	  msg_class = @data.class.to_s.gsub(/^.*::/, '').downcase
	  handle(msg_class)
	end

	def handle(msg_class)
	  if %w{discover request inform release}.include?(msg_class)
	    @pool = Pool.query(@data.hwaddr, msg_class.to_sym)
	    @pool ? send("#{msg_class}_handler".to_sym) : false
	  else
	    raise NoMessageHandler, 'No appropriate handler for message.'
	  end
	end

	def discover_handler
	    @reply.data = DHCP::Offer.new
	    create_reply
	end

	def request_handler
	    @reply.data = DHCP::ACK.new
	    create_reply
	end

	def release_handler
	  @reply.data = nil
	end

	def inform_handler
	  @reply.data = DHCP::ACK.new
	  create_reply
	end

	def create_reply
	  @reply.data.yiaddr = @pool.data.yiaddr
	  @reply.data.fname = @pool.data.fname
	  @reply.data.options = @pool.data.options
	  @reply.data.siaddr = IPAddr.new(Blondy::DHCPD::CONFIG['server_ip']).to_i
	  @reply.data.xid = @data.xid if @data.xid
	  @reply.ip = '255.255.255.255'
	  set_port
	  @reply
	end

	def set_port
	  @reply.port = 68
	  if @data.giaddr == 0 and @data.ciaddr != 0
	    @reply.ip = IPAddr.new(@data.ciaddr, family = Socket::AF_INET).to_s
	  elsif @data.giaddr != 0
	    @reply.ip = IPAddr.new(@data.giaddr, family = Socket::AF_INET).to_s
	    @reply.port = 67
	  else
	    false
	  end
	end
      end
    end
  end
end

class NoMessageHandler < StandardError
end
class IncorrectMessage < StandardError
end

