require 'spec_helper'

module Blondy
  module DHCPD
    describe 'Logger' do
      it 'set logger' do
	Logger.class.should eql(Log4r::Logger)
	Logger.outputters.should_not be_empty
      end
    end 
  end
end
