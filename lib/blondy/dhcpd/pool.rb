require 'em-http'

module Blondy
  module DHCPD
    class Pool
      class << self
	def query(hwaddr, type)
	  if Cache.query(hwaddr,type) 
	    false
	  else
	    http = EM::HttpRequest.new(Blondy::DHCPD::CONFIG['master'])
	    http.get(head: {'x-blondy-key' => Blondy::DHCPD::CONFIG['client_key']}, query: {'type' => type.to_s, 'hwaddr' => hwaddr})
	  end
	end
      end
    end
  end
end
