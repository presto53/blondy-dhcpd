
module Blondy
  module DHCPD
    class Cache
      @cache = Hash.new
      class << self
	def add(hwaddr,type, data)
	  @cache[type] = Hash.new unless @cache[type]
	  @cache[type][hwaddr] = Hash.new unless @cache[type][hwaddr]
	  @cache[type][hwaddr][:data] = data
	  @cache[type][hwaddr][:time] = Time.now
	end
	def query(hwaddr, type)
	  begin
	    @cache[type][hwaddr][:data] ? @cache[type][hwaddr] : false
	  rescue
	    false
	  end
	end
	def flush
	  @cache.clear
	end
	def purge(sec)
	  @cache.each do |type, data|
	    data.each_key do |hwaddr|
	      @cache[type].delete hwaddr if (Time.now - @cache[type][hwaddr][:time]) >= sec
	    end
	  end
	end
      end
    end
  end
end
