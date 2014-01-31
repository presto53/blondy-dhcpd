require 'spec_helper'

module Blondy
  module DHCPD
    describe 'Cache' do
      subject(:cache) {Cache}
      let(:data) do
	pool_query_result = OpenStruct.new 
	pool_query_result.data = OpenStruct.new 
	pool_query_result.data.fname = 'test.txt'.unpack('C128').map {|x| x ? x : 0}
	pool_query_result.data.yiaddr = IPAddr.new('192.168.5.150').to_i
	pool_query_result.data.options = [
	  DHCP::MessageTypeOption.new({payload: [$DHCP_MSG_OFFER]}),
	  DHCP::ServerIdentifierOption.new({payload: Blondy::DHCPD::CONFIG['server_ip'].split('.').map {|octet| octet.to_i}}),
	  DHCP::DomainNameOption.new({payload: 'example.com'.unpack('C*')}),
	  DHCP::DomainNameServerOption.new({payload: [8,8,8,8]}),
	  DHCP::IPAddressLeaseTimeOption.new({payload: [7200].pack('N').unpack('C*')}),
	  DHCP::SubnetMaskOption.new({payload: [255, 255, 255, 255]}),
	  DHCP::RouterOption.new({payload: [192, 168, 1, 3]})
	]
	pool_query_result
      end

      it 'add host to cache' do
	cache.query('11:11:11:11:11:11', :discover).should == false 
	cache.add('11:11:11:11:11:11', :discover, data)
	cache.query('11:11:11:11:11:11', :discover)[:data].should == data
      end
      it 'flush cache' do
	cache.add('11:11:11:11:11:11', :discover, data)
	cache.add('12:11:11:11:11:11', :discover, data)
	cache.flush
	cache.query('11:11:11:11:11:11', :discover).should == false
	cache.query('12:11:11:11:11:11', :discover).should == false
      end
      it 'delete entries older than N' do
	@time = Time.now
	Time.stub(:now) {@time}
	cache.add('11:11:11:11:11:11', :discover, data)
	Time.stub(:now) {@time+5}
	cache.purge(3)
	cache.query('11:11:11:11:11:11', :discover).should == false
      end
    end
  end
end
