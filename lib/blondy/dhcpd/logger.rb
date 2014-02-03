require 'log4r'

module Blondy
  module DHCPD
    # Set logger
    Logger = Log4r::Logger.new 'ruby-dhcpd'
    Logger.outputters << Log4r::Outputter.stdout
  end
end

