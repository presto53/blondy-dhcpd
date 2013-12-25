require 'spec_helper'

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
	# RFC 2131
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
	let(:reply) {DHCP::Offer.new}

	context 'giaddr != 0' do
	  it 'send offer message to' do
	    pending
	    server.should_receive(:send_data).with()
	    server.receive_data(data)
	  end
	end
	context 'giaddr = 0 and ciaddr != 0' do
	  it 'send offer message' do
	    pending
	    server.should_receive(:send_data).with()
	    server.receive_data(data)
	  end
	end
	context 'giaddr = 0 and ciaddr = 0 and broadcast = true' do
	  it 'send offer message to' do
	    pending
	    server.should_receive(:send_data).with()
	    server.receive_data(data)
	  end
	end
	context 'giaddr = 0 and ciaddr = 0 and broadcast = false' do
	  it 'send offer message to' do
	    pending
	    server.should_receive(:send_data).with()
	    server.receive_data(data)
	  end
	end
      end
    end
  end
end
