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
	      if http.response_header.status != 200
		Logger.error "Remote server reply with #{http.response_header.status} error code."
	      else
		data = transform(http.response)
		Cache.add(hwaddr,type, data) if data
	      end
	    end
	    http.errback do
	      Logger.error "Error while requesting remote server. '#{http.error}'"
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
