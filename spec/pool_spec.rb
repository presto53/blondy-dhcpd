require 'spec_helper'

module Blondy
  module DHCPD

    class Cache
      @cache = Hash.new
      class << self
	def add(hwaddr,type, data)
	  @cache[type] = Hash.new unless @cache[type]
	  @cache[type][hwaddr] = Hash.new unless @cache[type][hwaddr]
	  @cache[type][hwaddr][:data] = data
	  @cache[type][hwaddr][:time] = Time.now
	end
	def query(hwaddr, type)
	  begin
	    @cache[type][hwaddr][:data] ? @cache[type][hwaddr][:data] : false
	  rescue
	    false
	  end
	end
      end
    end

    describe 'Pool' do
      subject(:pool) {Pool}
      let(:cache) {Cache}
      let(:remote_json) { {'a' => 'b', 'c' => 'd'}.to_json }
      #TODO add real data example
      let(:reply_data) { {'a' => 'b', 'c' => 'd'} }

      describe 'receive query' do

	before(:each) do
	  stub_request(:get, "https://127.0.0.1/blondy/dhcpd?hwaddr=11:11:11:11:11:11&type=discover").
	    with(:headers => {'X-Blondy-Key'=>'abcd'}).
	    to_return(:status => 200, :body => remote_json, :headers => {})
	end

	it 'check for reply in cache' do
	  cache.should_receive(:query).with('11:11:11:11:11:11', :discover)
	  pool.query('11:11:11:11:11:11', :discover)
	end

	context 'not found in cache' do
	  it 'initiate query to remote server' do
	    pool.query('11:11:11:11:11:11', :discover)
	    WebMock.should have_requested(:get, "https://127.0.0.1/blondy/dhcpd?hwaddr=11:11:11:11:11:11&type=discover")
	  end
	  it 'reply with false' do
	    pool.query('11:11:11:11:11:11', :discover).should == false
	  end
	  it 'set received data to cache' do
	    pending 'didn\'t work'
	    pool.query('11:11:11:11:11:11', :discover)
	    pool.query('11:11:11:11:11:11', :discover).should == reply_data
	    cache.query('11:11:11:11:11:11', :discover).should == reply_data
	    #WebMock.after_request do |request_signature, response|
	    #end
	  end
	end

	context 'found in cache' do
	  before(:each) do
	    allow(cache).to receive(:query).with('11:11:11:11:11:11', :discover).and_return(reply_data)
	  end

	  it 'return reply data' do
	    pool.query('11:11:11:11:11:11', :discover).should == reply_data
	  end
	end

	#context 'remote pool reply correctly' do
	#context 'data converted correctly' do
	#before(:each) do
	#allow(pool).to receive(:transform).with(remote_json).and_return(reply_data)
	#end
	#it 'set values to cache' do
	#pool.query('11:11:11:11:11:11', :discover)
	#cache.query('11:11:11:11:11:11', :discover).should be_true
	#end
	#it 'return converted reply from remote pool' do
	#pool.query('11:11:11:11:11:11', :discover).should == reply_data
	#end
	#end
	#context 'data is not converted' do
	#before(:each) do
	#allow(pool).to receive(:transform).with('false data').and_return(false)
	#end
	#it 'log that incorrect data received' do
	#pending
	#end
	#end
	#end
	#context 'remote pool reply with error' do
	#before(:each) do
	#stub_request(:get, "https://127.0.0.1/blondy/dhcpd?hwaddr=11:11:11:11:11:11&type=discover").
	#with(:headers => {'X-Blondy-Key'=>'abcd'}).
	#to_return(:status => 500, :body => "", :headers => {})
	#end
	#it 'log error code' do
	#pending
	#end
	#it 'not set values to cache' do
	#pending
	#cache.should_not_receive(:add)
	#pool.query('11:11:11:11:11:11', :discover)
	#end
	#end
	#context 'remote pool unavailable' do
	#before(:each) do
	#stub_request(:get, "https://127.0.0.1/blondy/dhcpd?hwaddr=11:11:11:11:11:11&type=discover").
	#with(:headers => {'X-Blondy-Key'=>'abcd'}).
	#to_timeout
	#end
	#it 'log that pool unavailable' do
	#pending
	#end
	#it 'not set values to cache' do
	#pending
	#cache.should_not_receive(:add)
	#pool.query('11:11:11:11:11:11', :discover)
	#end
	#end
	#end

      end
    end
  end
end
