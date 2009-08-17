class MemcacheExpiration
  require 'rubygems'
  require 'memcache'

  @connection = nil
  @namespace = nil

  def initialize(namespace = "opencongress_#{RAILS_ENV}")
    @namespace = namespace
    connect
  end

  def show_stats
    connect unless connection_active?
    
    return @connection.stats
  end

  def show_one_frag(fragment)
    connect unless connection_active?

    return @connection.get("views/#{fragment}", true)
  end

  def expire_frag(fragment)
    connect unless connection_active?
    
    if fragment.class.to_s == "Array"
      fragment.each do |f|
        f = "views/#{f}"
        @connection.delete(f)
      end
    else
      @connection.delete("views/#{fragment}")
    end
  end

  def flush_all 
    connect unless @connection.active?
    
    return @connection.flush_all rescue nil
  end

  protected
  
  def connection_active?
    begin
      stats = @connection.stats
      return true if stats
    rescue
      return false
    end
  end

  def connect
    hostport = '10.13.219.6:11211' unless RAILS_ENV=="test"
    hostport = 'localhost:11211' if RAILS_ENV=="test"
    errorcount = 0
    
    while errorcount < 5
      begin
        @connection = MemCache.new(hostport, :namespace => @namespace)
        return if connection_active?
      rescue
        puts "Error connecting to memcache server.  Trying again..."
        errorcount += 1
      end
    end
    
    raise "Could not connect to memcache server!!"
  end
end
