require './lib/rest_client_proxy'

describe 'RestClientProxyCall' do
  before do
    @client_w_uri      = mock("LoadBalancedRestClient::Client", :get => true)
    @client            = mock("LoadBalancedRestClient::Client", :[] => @client_w_uri)
    @server            = mock("LoadBalancedRestClient::Server", :client => @client)
    @load_balancer     = mock("LoadBalancedRestClient::LoadBalancer", :with_server => @server)
    @proxy_call_w_res  = LoadBalancedRestClient::RestClientProxyCall.new(@load_balancer, "test")
    @proxy_call_wo_res = LoadBalancedRestClient::RestClientProxyCall.new(@load_balancer)
  end

  context "with a sub-resource" do
    it "delegates to RestClient" do
      @load_balancer.should_receive(:with_server).and_yield(@server)
      @server.should_receive(:client)
      @client.should_receive(:[]).with("test")
      @client_w_uri.should_receive(:get)

      @proxy_call_w_res.get
    end
  end

  context "without a sub-resource" do
    it "delegates to RestClient" do
      @load_balancer.should_receive(:with_server).and_yield(@server)
      @server.should_receive(:client)
      @client.should_receive(:get)

      @proxy_call_wo_res.get
    end
  end
end
