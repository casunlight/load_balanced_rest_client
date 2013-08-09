class LoadBalancedRestClient
  class Cluster
    class NoServers < StandardError; end
    attr_accessor :servers

    def initialize(servers, opts={})
      server_klass = opts[:server_klass] || Server

      if servers.first.class.to_s != "LoadBalancedRestClient::Server"
        @servers = servers.map {|server| server_klass.new(server, opts)}
      else
        @servers = servers
      end

      if servers.empty?
        raise NoServers.new("No servers in cluster") 
      end
    end

    def balance!
      @servers.push(@servers.delete(next_server))
    end

    def next_server
      servers_to_try.first || @servers.first
    end

    def servers_to_try
      @servers.select {|server| server.should_try? }
    end
  end
end
