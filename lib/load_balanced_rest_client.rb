require 'rest-client'
require 'logger'
require_relative 'version'
require_relative 'server'
require_relative 'cluster'
require_relative 'algorithms'
require_relative 'load_balancer'
require_relative 'rest_client_proxy'

class LoadBalancedRestClient
  attr_accessor :cluster, :load_balancer
  include RestClientProxy

  def initialize(servers, opts={})
    @cluster       = Cluster.new(servers, opts)
    @load_balancer = LoadBalancer.new(@cluster, opts)
  end
end
