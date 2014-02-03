require 'optparse'
require 'yaml'
require 'log4r'

module Blondy
  module DHCPD
    # Set default config
    default_config = '/etc/blondy/dhcpd.yml'
    config_file = default_config

    # Read command line options
    @options = Hash.new
    OptionParser.new do |opts|
      opts.banner = 'Usage: dhcpd.rb [options]'
      opts.on('-d', '--debug', 'Run foreground for debug') { @options[:debug] = true }
      opts.on_tail('-h', '--help', 'Show this message') do
	puts opts
	exit 0
      end
    end.parse!

    # Load config from file
    begin
      config_file = "#{ENV['BLONDY_CONFIGPATH']}/dhcpd.yml" if ENV['BLONDY_CONFIGPATH']
      CONFIG = YAML::load(File.open(config_file))
    rescue
      STDERR.puts "No config file. \nPlease check that #{default_config} exist or BLONDY_CONFIGPATH is set."
      exit 1
    end

    # Check for client key
    unless CONFIG['client_key']
      Logger.error 'You should set client_key.'
      exit 1
    end
    # Check for master address
    unless /^http(s)?:\/\/.*/ =~ CONFIG['master']
      Logger.error 'You should set master server.'
      exit 1
    end

    # Set logging to file
    if CONFIG['log_path']
      begin
	if /^\// =~ CONFIG['log_path']
	  log_path = CONFIG['log_path'].gsub(/\/*$/,'')
	  format = Log4r::PatternFormatter.new(:pattern => "[%l] [%d] %m")
	  Logger.outputters << Log4r::FileOutputter.new('blondy-dhcpd.log', filename: "#{log_path}/blondy-dhcpd.log" , formatter: format)
	end
	Logger.level = ((1..7).include?(CONFIG['log_level']) ? CONFIG['log_level'] : 1)
      rescue
	Logger.error 'Error while open log file.'
      end
    end
  end
end
