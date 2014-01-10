require 'eventmachine'
require 'yaml'
require_relative 'dhcpd/server'
require_relative 'dhcpd/logger'

default_config = '/etc/blondy/dhcpd.yml'

begin
  Blondy::DHCPD::CONFIG = YAML::load(File.open(ENV['BLONDY_CONFIGPATH'] || default_config))
rescue
  STDERR.puts "No config file. \nPlease check that #{default_config} exist or BLONDY_CONFIGPATH is set."
  exit 1
end

if /^\// =~ Blondy::DHCPD::CONFIG['pid_path']
  pidf = "#{Blondy::DHCPD::CONFIG['pid_path'].gsub(/\/*$/,'')}/blondy-dhcpd.pid"
  running_pid = File.open(pidf, 'r').read.chomp rescue nil
  running_pgid = Process.getpgid(running_pid.to_i) rescue nil if running_pid
  if running_pgid
    STDERR.puts 'Daemon already running.'
    exit 1
  end
else
  STDERR.puts 'PID path is wrong or not set.'
  Blondy::DHCPD::Logger.error 'PID path is wrong or not set.'
  exit 1
end

Process.daemon
File.write(pidf, "#{Process.pid}\n")

Signal.trap("TERM") do
  EM.stop
  File.delete(pidf) if File.exists?(pidf)
  exit 0
end

EM.run do
  EM.open_datagram_socket('0.0.0.0', 67, Blondy::DHCPD::Server)
end
