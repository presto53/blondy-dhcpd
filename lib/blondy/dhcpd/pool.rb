require 'em-http'
require 'json'

module Blondy
  module DHCPD
    class Pool
      class << self
	def query(hwaddr, type)
	  reply = Cache.query(hwaddr,type)
	  if reply
	    reply
	  else
	    http = EM::HttpRequest.new(Blondy::DHCPD::CONFIG['master']).
	      get(head: {'x-blondy-key' => Blondy::DHCPD::CONFIG['client_key']}, query: {'type' => type.to_s, 'hwaddr' => hwaddr})
	    http.callback do
	      data = transform(http.response)
	      Cache.add(hwaddr,type, data) if data
	    end
	    false
	  end
	end
	
	private

	def transform(json)
	  data = JSON.parse(json) rescue false
	  #if data
	  # Here we will transform received data to our format
	  #end
	  data
	end
      end
    end
  end
end
