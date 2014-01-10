require 'log4r'

module Blondy
  module DHCPD
    Logger = Log4r::Logger.new 'ruby-dhcpd'
    Logger.outputters << Log4r::Outputter.stdout
    format = Log4r::PatternFormatter.new(:pattern => "[%l] [%d] %m")
    if /^\// =~ Blondy::DHCPD::CONFIG['log_path']
      log_path = Blondy::DHCPD::CONFIG['log_path'].gsub(/\/*$/,'')
      Logger.outputters << Log4r::FileOutputter.new('blondy-dhcpd.log', filename: "#{log_path}/blondy-dhcpd.log" , formatter: format)
    end
    Logger.level = ((1..7).include?(Blondy::DHCPD::CONFIG['log_level']) ? Blondy::DHCPD::CONFIG['log_level'] : 1)
  end
end
