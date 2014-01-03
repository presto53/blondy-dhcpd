require 'spec_helper'

module Blondy
  module DHCPD
    describe 'Dispatcher' do
      subject(:dispatcher) {Dispatcher}
      let(:pool) {Pool}
      let(:pool_query_result) do
	pr = OpenStruct.new
	pr.data = OpenStruct.new
	pr.data.fname = String.new
	pr.data.yiaddr = '0.0.0.0'
	pr.data.options = Array.new
	pr.code = 200
	pr
      end
      let(:from_ip) {'0.0.0.0'}
      let(:from_port) {67}
      [ :discover, :request, :release, :inform ].each do |message|
	let(message) do
	  msg_class = DHCP.const_get message.to_s.capitalize.to_sym
	  d = msg_class.new
	  d.xid = 123456789
	  d
	end
      end

      before(:each) do
	allow(pool).to receive(:query).and_return(pool_query_result)
	allow(pool).to receive(:query).with({hwaddr: 'ee:ee:ee:ee:ee:ee', type: :discover}).and_return(pool_query_result)
      end

      shared_examples_for Dispatcher do
	it 'data is correct' do
	  dispatcher.dispatch(discover.pack, from_ip, from_port).data.pack.should == reply.data.pack
	end
	it 'ip is correct' do
	  dispatcher.dispatch(discover.pack, from_ip, from_port).ip.should == reply.ip
	end
	it 'port is correct' do
	  dispatcher.dispatch(discover.pack, from_ip, from_port).port.should == reply.port
	end
      end

      %w{discover request release inform}.each do |message|
	context "receive dhcp #{message} message" do
	  it "dispatch it to specific #{message}_handler private method" do
	    dispatcher.should_receive("#{message}_handler".to_sym)
	    dispatcher.dispatch(eval(message).pack, from_ip, from_port)
	  end
	  if %w{discover request inform}.include? message
	    it 'reply xid is the same as received xid' do
	      dispatcher.dispatch(eval(message).pack, from_ip, from_port).data.xid.should == eval(message).xid
	    end
	  end
	end
      end

      context 'wrong message' do
	it 'false when message is unknown' do
	  lambda { dispatcher.dispatch("abracadabra", from_ip, from_port) }.should raise_error(IncorrectMessage)
	end
	it 'false when action for message unspecified' do
	  lambda { dispatcher.dispatch("abracadabra", from_ip, from_port) }.should raise_error(IncorrectMessage)
	end
      end

      describe 'receive discovery message' do
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
	  reply.data.xid = discover.xid
	  reply.data.options = pool_query_result.data.options
	  reply.data.yiaddr = IPAddr.new(pool_query_result.data.yiaddr).to_i
	  reply.data.fname = pool_query_result.data.fname.unpack('C128').map {|x| x ? x : 0}
	  reply
	end

	before(:each) do
	  discover.chaddr = [238, 238, 238, 238, 238, 238, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	  discover.hlen = 6
	  pool_query_result.data.fname = 'test.txt'
	  pool_query_result.data.yiaddr = '192.168.5.150'
	  pool_query_result.data.options = [
	    DHCP::MessageTypeOption.new({payload: [$DHCP_MSG_OFFER]}),
	    DHCP::ServerIdentifierOption.new({payload: [192, 168, 1, 1]}),
	    DHCP::DomainNameOption.new({payload: 'example.com'.unpack('C*')}),
	    DHCP::DomainNameServerOption.new({payload: [8,8,8,8]}),
	    DHCP::IPAddressLeaseTimeOption.new({payload: [7200].pack('N').unpack('C*')}),
	    DHCP::SubnetMaskOption.new({payload: [255, 255, 255, 255]}),
	    DHCP::RouterOption.new({payload: [192, 168, 1, 1]})
	  ]
	end

	context 'giaddr != 0' do
	  #reply with offer message to bootp relay
	  before(:each) do
	    giaddr = '192.168.3.3'
	    discover.giaddr = IPAddr.new(giaddr).to_i
	    reply.ip = giaddr
	    reply.port = 67
	  end
	  it_behaves_like Dispatcher
	end
	context 'giaddr = 0 and ciaddr != 0' do
	  #send offer message to client
	  before(:each) do
	    ciaddr = '192.168.3.4'
	    discover.ciaddr = IPAddr.new(ciaddr).to_i
	    reply.ip = ciaddr
	    reply.port = 68
	  end
	  it_behaves_like Dispatcher
	end
	context 'giaddr = 0 and ciaddr = 0' do
	  #send offer message to client by broadcast to 255.255.255.255
	  before(:each) do
	    discover.flags = 1
	    reply.ip = '255.255.255.255'
	    reply.port = 68
	  end
	  it_behaves_like Dispatcher
	end

	context 'ask pool for configuration' do
	  context 'query already found in cache' do
	    it 'not reply for message' do
	      pool.should_receive(:query).with({hwaddr: 'ee:ee:ee:ee:ee:ee', type: :discover}).and_return(false)
	      dispatcher.dispatch(discover.pack, from_ip, from_port).should be_false
	    end
	  end
	  context 'query not found in cache' do
	    it 'set reply fields according to pool query result' do
	      dispatcher.dispatch(discover.pack, from_ip, from_port).data.fname.should == pool_query_result.data.fname.unpack('C128').map {|x| x ? x : 0}
	      dispatcher.dispatch(discover.pack, from_ip, from_port).data.yiaddr.should == IPAddr.new(pool_query_result.data.yiaddr).to_i
	      dispatcher.dispatch(discover.pack, from_ip, from_port).data.options.should == pool_query_result.data.options
	    end
	    it 'set siaddr to server ip address' do
	      pending
	    end
	  end
	end
      end
    end
  end
end

