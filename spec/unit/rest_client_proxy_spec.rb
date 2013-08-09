require './lib/rest_client_proxy'

describe 'RestClientProxyCall' do
  before do
    @client_w_uri      = mock("LoadBalancedRestClient::Client", :get => true)
    @client            = mock("LoadBalancedRestClient::Client", :[] => @client_w_uri)
    @server            = mock("LoadBalancedRestClient::Server", :client => @client)
    @load_balancer     = mock("LoadBalancedRestClient::LoadBalancer", :with_server => @server)
    @proxy_call        = LoadBalancedRestClient::RestClientProxyCall.new(@load_balancer, "test")
  end

  it "delegates to RestClient" do
    @load_balancer.should_receive(:with_server).and_yield(@server)
    @server.should_receive(:client)
    @client.should_receive(:[]).with("test")
    @client_w_uri.should_receive(:get)

    @proxy_call.get
  end
end
