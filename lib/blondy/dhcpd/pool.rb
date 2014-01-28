require 'em-http'
require 'json'
require 'net-dhcp'
require 'ipaddr'
require 'ostruct'

module Blondy
  module DHCPD
    class Pool
      class << self
	def query(hwaddr, type)
	  reply = Cache.query(hwaddr,type)
	  if reply
	    reply
	  else
	    http = EM::HttpRequest.new(Blondy::DHCPD::CONFIG['master']).
	      get(head: {'x-blondy-key' => Blondy::DHCPD::CONFIG['client_key']}, query: {'type' => type.to_s, 'hwaddr' => hwaddr})
	    http.callback do
	      if http.response_header.status != 200
		Logger.error "Remote server reply with #{http.response_header.status} error code."
	      else
		data = transform(http.response, type)
		Cache.add(hwaddr,type, data) if data
	      end
	      data
	    end
	    http.errback do
	      Logger.error 'Remote pool server is unavailable.'
	    end
	    false
	  end
	end

	private

	def transform(json, type)
	  begin
	    data = JSON.parse(json)
	    if type == :discover
	      reply_type = $DHCP_MSG_OFFER
	    elsif type == :request
	      reply_type = $DHCP_MSG_ACK
	    else
	      raise UnsupportedReqType
	    end
	    result = OpenStruct.new 
	    result.data = OpenStruct.new 
	    result.data.fname = data['fname'].unpack('C128').map {|x| x ? x : 0}
	    result.data.yiaddr = IPAddr.new(data['yiaddr']).to_i
	    result.data.options = [
	      DHCP::MessageTypeOption.new({payload: [reply_type]}),
	      DHCP::ServerIdentifierOption.new({payload: Blondy::DHCPD::CONFIG['server_ip'].split('.').map {|octet| octet.to_i}}),
	      DHCP::DomainNameOption.new({payload: data['domain'].unpack('C*')}),
	      DHCP::DomainNameServerOption.new({payload: (data['dns'].split('.').map {|octet| octet.to_i} if IPAddr.new(data['dns']))}),
	      DHCP::IPAddressLeaseTimeOption.new({payload: [7200].pack('N').unpack('C*')}),
	      DHCP::SubnetMaskOption.new({payload: (data['netmask'].split('.').map {|octet| octet.to_i} if IPAddr.new(data['netmask']))}),
	      DHCP::RouterOption.new({payload: (data['gw'].split('.').map {|octet| octet.to_i} if IPAddr.new(data['gw']))})
	    ]
	    result
	  rescue UnsupportedReqType
	    # Unsupported request type
	    Logger.error 'Unsupported type received.'
	    false
	  rescue JSON::ParserError
	    # Wrong json
	    Logger.error 'Remote server send invalid json.'
	    false
	  rescue NoMethodError
	    Logger.error 'Remote server send invalid text data in json.'
	    # Wrong data in json
	    false
	  rescue IPAddr::AddressFamilyError
	    # Wrong data in json (address family must be specified)
	    Logger.error 'Remote server send invalid ip or nemask in json.'
	    false
	  rescue IPAddr::InvalidAddressError
	    # Wrong data in json (invalid address)
	    Logger.error 'Remote server send invalid ip or nemask in json.'
	    false
	  rescue
	    # Unknown error
	    Logger.error 'Unknown error.'
	    false
	  end
	end
      end
    end
  end
end
class UnsupportedReqType < StandardError
end
