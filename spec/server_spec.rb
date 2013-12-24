require 'spec_helper'

module Blondy
  module DHCPD
    describe 'Server' do
      before(:each) do
	allow(EM).to receive(:open_udp_socket).and_return 0
      end
      subject(:server) {EM.open_datagram_socket('127.0.0.1', 67, Server)}
      let(:dispatcher) {Dispatcher}

      context 'receive any message'do
	let(:data) {'test data'}
	it 'run dispatcher' do
	  dispatcher.should_receive(:dispatch).with(data)
	  server.receive_data(data)
	end
      end
      #context 'receive discovery message' do
      #let(:data) {Net::DHCP::Discover.new.pack}
      #it 'send Offer message' do
      #pending
      #end
      #end
    end
  end
end
