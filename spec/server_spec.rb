require 'spec_helper'

# nasty hack to avoid creating new thread
module EM
  def self.defer(op, callback)
    callback.call(op.call)
  end
end

module Blondy
  module DHCPD
    describe 'Server' do
      subject(:server) {EM.open_datagram_socket('127.0.0.1', 67, Server)}
      let(:dispatcher) {Dispatcher}
      let(:discover) do
	d = DHCP::Discover.new
	d.xid = 123456789
	d
      end
      let(:logger) {Logger}

      before(:each) do
	allow(EM).to receive(:open_udp_socket).and_return 0
	allow(Socket).to receive(:unpack_sockaddr_in).and_return ['0.0.0.0', '68']
	allow(Logger).to receive(:info)
	allow(Logger).to receive(:warn)
	allow(Logger).to receive(:error)
      end

      it 'has defined buffer' do
	server.instance_variable_defined?('@buffer').should be_true
      end

      describe 'receive message' do
	before(:each) do
	  @ip, @port = Socket.unpack_sockaddr_in(server.get_peername)
	end

	it 'add received data in buffer' do
	  server.receive_data('test data')
	  server.instance_variable_get('@buffer').include?('test data').should be_true
	end
	context 'buffer include DHCP magic number' do
	  it 'run dispatcher' do
	    dispatcher.should_receive(:dispatch).with(discover.pack, @ip, @port)
	    server.receive_data(discover.pack)
	  end
	  it 'clear buffer' do
	    server.receive_data(discover.pack)
	    server.instance_variable_get('@buffer').size.should eq(0)
	  end
	end
	context 'buffer not include DHCP magic' do
	  # Maximum dhcp message size is 576 bytes (but client can increase it)
	  # So we will try with 1000 bytes buffer
	  context 'data size in buffer is greater than 1000 bytes' do
	    it 'clear buffer' do
	      dummy_data = String.new
	      1000.times { dummy_data += rand(9).to_s }
	      server.instance_variable_set('@buffer', dummy_data)
	      server.receive_data(discover.pack.byteslice(0,15))
	      server.instance_variable_get('@buffer').size.should eq(15)
	    end
	  end
	  it 'shoul not clear buffer' do
	    server.receive_data(discover.pack.byteslice(0,10))
	    server.instance_variable_get('@buffer').size.should eq(10)
	  end
	end

	context 'receive dhcp message' do
	  it 'send reply' do
	    reply = OpenStruct.new
	    reply.data = DHCP::Offer.new
	    allow(dispatcher).to receive(:dispatch).and_return(reply)
	    server.should_receive(:send_datagram)
	    server.receive_data(discover.pack)
	  end
	  context 'wrong data' do
	    it 'not send reply' do
	      server.should_not_receive(:send_datagram)
	      server.receive_data('abracadabra')
	    end
	    context 'can not convert received data to Message object' do
	      it 'should log error' do
		logger.should_receive(:warn).with('Incorrect message received. Ignore.')
		discover.options.shift
		server.receive_data(discover.pack)
	      end
	    end
	    context 'no handler for message' do
	      it 'should log error' do
		logger.should_receive(:warn).with('No handler for message found. Ignore.')
		server.receive_data(DHCP::Offer.new.pack)
	      end
	    end
	  end
	end
      end
    end
  end
end
