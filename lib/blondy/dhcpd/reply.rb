require 'net-dhcp'
require 'ostruct'
require 'ipaddr'

module Blondy
  module DHCPD
    class Reply
      def initialize(data, reply_type)
	  @result = OpenStruct.new 
	  @result.data = OpenStruct.new
	  @data = data
	  @reply_type = reply_type
	  @result.data.fname = data['fname'].unpack('C128').map {|x| x ? x : 0}
	  @result.data.yiaddr = IPAddr.new(data['yiaddr']).to_i
	  @result.data.options = [
	    DHCP::MessageTypeOption.new({payload: [@reply_type]}),
	    DHCP::ServerIdentifierOption.new({payload: array_from(Blondy::DHCPD::CONFIG['server_ip'])}),
	    DHCP::DomainNameOption.new({payload: data['domain'].unpack('C*')}),
	    DHCP::DomainNameServerOption.new({payload: array_from(data['dns'])}),
	    DHCP::IPAddressLeaseTimeOption.new({payload: [7200].pack('N').unpack('C*')}),
	    DHCP::SubnetMaskOption.new({payload: array_from(data['netmask'])}),
	    DHCP::RouterOption.new({payload: array_from(data['gw'])})
	  ]
      end

      def get
	@result
      end

      private
      
      def array_from(ip)
	ip.split('.').map {|octet| octet.to_i} if IPAddr.new(ip)
      end
    end
  end
end
