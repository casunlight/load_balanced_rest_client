class LoadBalancedRestClient
  class RestClientProxyCall
    def initialize(load_balancer, uri = nil)
      @load_balancer = load_balancer
      @uri           = uri
    end

    def method_missing(method_name, *args, &blk)
      @load_balancer.with_server do |server|
        server.client[@uri].send(method_name, *args, &blk)
      end
    end
  end

  module RestClientProxy
    def [](uri)
      RestClientProxyCall.new(@load_balancer, uri)
    end

    def method_missing(method_name, *args, &blk)
      RestClientProxyCall.new(@load_balancer).send(method_name, *args, &blk)
    end
  end
end
