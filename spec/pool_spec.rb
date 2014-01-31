require 'spec_helper'

module Blondy
  module DHCPD

    describe 'Pool' do
      subject(:pool) {Pool}
      let(:cache) {Cache}
      let(:logger) {Logger}
      let(:remote_json) { {'fname' => 'test.txt', 
			   'yiaddr' => '192.168.5.150', 
			   'domain' => 'example.com', 
			   'dns' => '8.8.8.8', 
			   'gw' => '192.168.1.3', 
			   'netmask' => '255.255.255.255' }.to_json }
      let(:remote_invalid_json) { { 'netaddr' => 'invalid', 'yomask' => '' }.to_json }
      let(:reply_data) do
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

      describe 'receive query' do

	before(:each) do
	  cache.flush
	  stub_request(:get, "https://127.0.0.1/blondy/dhcpd?hwaddr=11:11:11:11:11:11&type=discover").
	    with(:headers => {'X-Blondy-Key'=>'abcd'}).
	    to_return(:status => 200, :body => remote_json, :headers => {})
	end

	it 'check for reply in cache' do
	  cache.should_receive(:query).with('11:11:11:11:11:11', :discover)
	  pool.query('11:11:11:11:11:11', :discover)
	end

	context 'not found in cache' do
	  before(:each) do
	    allow(cache).to receive(:query).with('11:11:11:11:11:11', :discover).and_return(false)
	  end
	  it 'initiate query to remote server' do
	    pool.query('11:11:11:11:11:11', :discover)
	    WebMock.should have_requested(:get, "https://127.0.0.1/blondy/dhcpd?hwaddr=11:11:11:11:11:11&type=discover")
	  end
	  it 'reply with false' do
	    pool.query('11:11:11:11:11:11', :discover).should == false
	  end
	  it 'set received data to cache', :no_em do
	    cache.stub(:query) { cache.unstub(:query); false }
	    EM.run_block { pool.query('11:11:11:11:11:11', :discover) }
	    cache.query('11:11:11:11:11:11', :discover)[:data].should == reply_data
	  end
	end

	context 'found in cache' do
	  before(:each) do
	    allow(cache).to receive(:query).with('11:11:11:11:11:11', :discover).and_return({data:reply_data, time: Time.now})
	  end

	  it 'return reply data' do
	    pool.query('11:11:11:11:11:11', :discover).should == reply_data
	  end
	end

	context 'remote pool unavailable' do
	  before(:each) do
	    stub_request(:get, "https://127.0.0.1/blondy/dhcpd?hwaddr=11:11:11:11:11:11&type=discover").
	      with(:headers => {'X-Blondy-Key'=>'abcd'}).
	      to_timeout
	  end
	  it 'log that pool unavailable', :no_em do
	    logger.should_receive(:error).with('Remote pool server is unavailable.')
	    EM.run_block { pool.query('11:11:11:11:11:11', :discover) }
	  end
	  it 'not set values to cache' do
	    cache.should_not_receive(:add)
	    pool.query('11:11:11:11:11:11', :discover)
	  end
	end

	context 'remote pool send incorrect data' do
	  before(:each) do
	    stub_request(:get, "https://127.0.0.1/blondy/dhcpd?hwaddr=11:11:11:11:11:11&type=discover").
	      with(:headers => {'X-Blondy-Key'=>'abcd'}).
	      to_return(:status => 200, :body => remote_invalid_json, :headers => {})
	  end
	  it 'return false' do
	    pool.query('11:11:11:11:11:11', :discover).should be_false
	  end
	end

	context 'remote pool reply with error' do
	  before(:each) do
	    stub_request(:get, "https://127.0.0.1/blondy/dhcpd?hwaddr=11:11:11:11:11:11&type=discover").
	      with(:headers => {'X-Blondy-Key'=>'abcd'}).
	      to_return(:status => 500, :body => "", :headers => {})
	  end
	  it 'log error code', :no_em do
	    logger.should_receive(:error).with('Remote server reply with 500 error code.')
	    EM.run_block { pool.query('11:11:11:11:11:11', :discover) }
	  end
	  it 'not set values to cache' do
	    cache.should_not_receive(:add)
	    pool.query('11:11:11:11:11:11', :discover)
	  end
	end

      end
    end
  end
end
