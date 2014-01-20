require 'spec_helper'

module Blondy
  module DHCPD

    describe 'Pool' do
      subject(:pool) {Pool}
      let(:cache) {Cache}

      describe 'receive query' do

	before(:each) do
	  stub_request(:get, "https://127.0.0.1/blondy/dhcpd?hwaddr=11:11:11:11:11:11&type=discover").
	    with(:headers => {'X-Blondy-Key'=>'abcd'}).
	    to_return(:status => 200, :body => "", :headers => {})
	end

	it 'check for reply in cache' do
	  cache.should_receive(:query).with('11:11:11:11:11:11', :discover)
	  pool.query('11:11:11:11:11:11', :discover)
	end

	context 'not found in cache' do
	  before(:each) do
	    allow(cache).to receive(:query).and_return(false)
	  end

	  it 'initiate query to remote server' do
	    pending
	    #WebMock.should have_requested(:get, "https://127.0.0.1/blondy/dhcpd?hwaddr=11:11:11:11:11:11&type=discover")
	    #a_request(:get, "https://127.0.0.1/blondy/dhcpd?hwaddr=11:11:11:11:11:11&type=discover").should have_been_made
	    pool.query('11:11:11:11:11:11', :discover)
	  end
	  context 'remote pool reply correctly' do
	    it 'return reply from remote pool' do
	      pending
	    end
	    it 'set values to cache' do
	      pending
	    end
	  end
	  context 'remote pool reply with error' do
	    it 'log error code' do
	      pending
	    end
	  end
	  context 'remote pool unavailable' do
	    it 'log that pool unavailable' do
	      pending
	    end
	  end
	end

	context 'found in cache' do
	  before(:each) do
	    allow(cache).to receive(:query).and_return(true)
	  end

	  it 'return false' do
	    pool.query('11:11:11:11:11:11', :discover).should == false
	  end
	end
      end
    end
  end
end
