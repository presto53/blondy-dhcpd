require 'spec_helper'
require 'ostruct'
require 'ipaddr'

module Blondy
  module DHCPD
    describe 'Server' do
      subject(:server) {EM.open_datagram_socket('127.0.0.1', 67, Server)}
      let(:dispatcher) {Dispatcher}
      before(:each) do
	allow(EM).to receive(:open_udp_socket).and_return 0
	allow(Socket).to receive(:unpack_sockaddr_in).and_return ['0.0.0.0', '68']
      end

      context 'receive any message'do
	let(:data) {'test data'}
	it 'run dispatcher' do
	  ip, port = Socket.unpack_sockaddr_in(server.get_peername)
	  dispatcher.any_instance.should_receive(:dispatch).with(data, ip, port)
	  server.receive_data(data)
	end
      end
      context 'receive discovery message' do
	# RFC 2131 (http://www.ietf.org/rfc/rfc2131.txt)
	#
	# http://stackoverflow.com/a/10757849
	#
	# If the 'giaddr' field in a DHCP message from a client is non-zero,
	# the server sends any return messages to the 'DHCP server' port on
	# the BOOTP relay agent whose address appears in 'giaddr'.
	# If the 'giaddr' field is zero and the 'ciaddr' field is nonzero,
	# then the server unicasts DHCPOFFER and DHCPACK messages to the address in 'ciaddr'.
	# If 'giaddr' is zero and 'ciaddr' is zero, and the broadcast bit is set,
	# then the server broadcasts DHCPOFFER and DHCPACK messages to 0xffffffff.
	# If the broadcast bit is not set and 'giaddr' is zero and 'ciaddr' is zero,
	# then the server unicasts DHCPOFFER and DHCPACK messages to the client's hardware address
	# and 'yiaddr' address. In all cases, when 'giaddr' is zero,
	# the server broadcasts any DHCPNAK messages to 0xffffffff.
	let(:data) {DHCP::Discover.new}
	let(:reply) do
	  reply = OpenStruct.new
	  reply.data = DHCP::Offer.new
	  reply.ipaddr = nil
	  reply.port = nil
	  reply
	end

	context 'giaddr != 0' do
	  it 'send offer message to bootp relay' do
	    data.giaddr = IPAddr.new('192.168.3.3').to_i
	    server.should_receive(:send_data).with(reply.data.pack, '192.168.3.3', 67)
	    server.receive_data(data.pack)
	  end
	end
	context 'giaddr = 0 and ciaddr != 0' do
	  it 'send offer message to client by unicast' do
	    data.ciaddr = IPAddr.new('192.168.3.3').to_i
	    server.should_receive(:send_data).with(reply.data.pack, '192.168.3.3', 68)
	    server.receive_data(data.pack)
	  end
	end
	context 'giaddr = 0 and ciaddr = 0 and flags = 1' do
	  it 'send offer message to client by broadcast to 255.255.255.255' do
	    data.flags = 1
	    server.should_receive(:send_data).with(reply.data.pack, '', 68)
	    server.receive_data(data.pack)
	  end
	end
	context 'giaddr = 0 and ciaddr = 0 and flags = 0' do
	  it 'send offer message to client by unicast it to client hwaddr and yiaddr' do
	    data.yiaddr = IPAddr.new('192.168.3.200').to_i
	    data.chaddr = [80, 229, 73, 35, 15, 112, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	    reply.data.chaddr.should eq(data.chaddr)
	    server.should_receive(:send_data).with(reply.data.pack, '192.168.3.200', 68)
	    server.receive_data(data.pack)
	  end
	end
      end
    end
  end
end
