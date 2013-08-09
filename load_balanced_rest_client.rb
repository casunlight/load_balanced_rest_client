require 'rest-client'
require 'logger'
require_relative 'lib/version'
require_relative 'lib/server'
require_relative 'lib/cluster'
require_relative 'lib/algorithms'
require_relative 'lib/load_balancer'
require_relative 'lib/rest_client_proxy'

class LoadBalancedRestClient
  attr_accessor :cluster, :load_balancer
  include RestClientProxy

  def initialize(servers, opts={})
    @cluster       = Cluster.new(servers, opts)
    @load_balancer = LoadBalancer.new(@cluster, opts)
  end
end
