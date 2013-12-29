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
      end

      context 'receive dhcp message' do
	before(:each) do
	  @ip, @port = Socket.unpack_sockaddr_in(server.get_peername)
	end
	it 'run dispatcher' do
	  dispatcher.should_receive(:dispatch).with(discover.pack, @ip, @port)
	  server.receive_data(discover.pack)
	end
	it 'send reply' do
	  server.should_receive(:send_datagram)
	  server.receive_data(discover.pack)
	end
	context 'wrong data' do
	  it 'not send reply' do
	    server.should_not_receive(:send_datagram)
	    server.receive_data('abracadabra')
	  end
	  it 'should log error' do
	    logger.should_receive(:info).with('Incorrect message. Ignore.')
	    server.receive_data('abracadabra')
	  end
	end
      end
    end
  end
end
