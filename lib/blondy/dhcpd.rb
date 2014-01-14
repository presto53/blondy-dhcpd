require 'eventmachine'
require 'yaml'
require 'log4r'
require_relative 'dhcpd/server'

module Blondy
  module DHCPD
    default_config = '/etc/blondy/dhcpd.yml'

    begin
      config_file = ( ENV['BLONDY_CONFIGPATH'] ? "#{ENV['BLONDY_CONFIGPATH']}/dhcpd.yml" : default_config )
      CONFIG = YAML::load(File.open(config_file))
    rescue
      STDERR.puts "No config file. \nPlease check that #{default_config} exist or BLONDY_CONFIGPATH is set."
      exit 1
    end

    Logger = Log4r::Logger.new 'ruby-dhcpd'
    Logger.outputters << Log4r::Outputter.stdout
    format = Log4r::PatternFormatter.new(:pattern => "[%l] [%d] %m")
    begin
      if /^\// =~ CONFIG['log_path']
	log_path = CONFIG['log_path'].gsub(/\/*$/,'')
	Logger.outputters << Log4r::FileOutputter.new('blondy-dhcpd.log', filename: "#{log_path}/blondy-dhcpd.log" , formatter: format)
      end
      Logger.level = ((1..7).include?(CONFIG['log_level']) ? CONFIG['log_level'] : 1)
    rescue
      STDERR.puts 'No config loaded or log_path missed.'
    end

    if /^\// =~ CONFIG['pid_path']
      @pidf = "#{CONFIG['pid_path'].gsub(/\/*$/,'')}/blondy-dhcpd.pid"
      running_pid = File.open(@pidf, 'r').read.chomp rescue nil
      running_pgid = Process.getpgid(running_pid.to_i) rescue nil if running_pid
      if running_pgid
	STDERR.puts 'Daemon already running.'
	exit 1
      end
    else
      STDERR.puts 'PID path is wrong or not set.'
      Logger.error 'PID path is wrong or not set.'
      exit 1
    end

    Process.daemon
    File.write(@pidf, "#{Process.pid}\n")
    Logger.info "Starting dhcpd with pid #{Process.pid}"

    class << self
      def shutdown
	EM.stop if EM.reactor_running?
	File.delete(@pidf) if File.exists?(@pidf)
	Logger.info "Server stopped."
      end
    end

    Signal.trap("TERM") do
      Logger.info "Server received TERM signal."
      shutdown
      exit 0
    end

    begin
      EM.run do
	EM.open_datagram_socket('0.0.0.0', 67, Server)
      end
    rescue
      Logger.error 'Failed to start server. Check that you start server from root.'
      shutdown
      exit 1
    end
  end
end
