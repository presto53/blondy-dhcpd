require 'spec_helper'
require 'ostruct'
require 'ipaddr'

module Blondy
  module DHCPD
    describe 'Dispatcher' do
      subject(:dispatcher) {Dispatcher}
      let(:from_ip) {'0.0.0.0'}
      let(:from_port) {67}
      let(:discover) do
	d = DHCP::Discover.new
	d.xid = 123456789
	d
      end

      context 'receive dhcp message' do
	it 'reply xid is the same as received xid' do
	  dispatcher.dispatch(discover.pack, from_ip, from_port).data.xid.should == discover.xid
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
	let(:reply) do
	  reply = OpenStruct.new
	  reply.data = DHCP::Offer.new
	  reply
	end

	context 'giaddr != 0' do
	  it 'send offer message to bootp relay' do
	    pending
	    data.giaddr = IPAddr.new('192.168.3.3').to_i
	    server.should_receive(:send_datagram).with(reply.data.pack, '192.168.3.3', 67)
	    server.receive_data(data.pack)
	  end
	end
	context 'giaddr = 0 and ciaddr != 0' do
	  it 'send offer message to client by unicast' do
	    pending
	    data.ciaddr = IPAddr.new('192.168.3.3').to_i
	    server.should_receive(:send_data).with(reply.data.pack, '192.168.3.3', 68)
	    server.receive_data(data.pack)
	  end
	end
	context 'giaddr = 0 and ciaddr = 0 and flags = 1' do
	  it 'send offer message to client by broadcast to 255.255.255.255' do
	    pending
	    data.flags = 1
	    server.should_receive(:send_data).with(reply.data.pack, '', 68)
	    server.receive_data(data.pack)
	  end
	end
	context 'giaddr = 0 and ciaddr = 0 and flags = 0' do
	  it 'send offer message to client by unicast it to client hwaddr and yiaddr' do
	    pending
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

