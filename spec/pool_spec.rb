require 'spec_helper'

module Blondy
  module DHCPD
    describe 'Pool' do
      describe 'receive query' do
	it 'check for reply in cache' do
	  pending
	end
	it 'initiate query to remote server' do
	  pending
	end
	context 'remote pool reply correctly' do
	  it 'return reply from remote pool' do
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
    end
  end
end
