require './lib/cluster.rb'

describe 'Cluster' do
  before do
    @server_klass  = mock("Server::Class", :new => true)
    @server_down_1 = mock("Server::Down1", :class => "LoadBalancedRestClient::Server", :to_s => "Down1", :should_try? => false)
    @server_down_2 = mock("Server::Down2",  :class => "LoadBalancedRestClient::Server", :to_s => "Down2", :should_try? => false)
    @server_down_3 = mock("Server::Down3", :class => "LoadBalancedRestClient::Server", :to_s => "Down3", :should_try? => false)
    @server_up_1   = mock("Server::Up1", :class => "LoadBalancedRestClient::Server", :to_s => "Up1", :should_try? => true)
    @server_up_2   = mock("Server::Up2", :class => "LoadBalancedRestClient::Server", :to_s => "Up2", :should_try? => true)
    @server_up_3   = mock("Server::Up3", :class => "LoadBalancedRestClient::Server", :to_s => "Up3", :should_try? => true)
    @cluster_klass = LoadBalancedRestClient::Cluster
    @servers       = [@server_down_1, @server_up_1, @server_up_2, @server_down_2, @server_down_3, @server_up_3]
    @cluster       = @cluster_klass.new(@servers, :server_klass => @server_klass)
  end

  context "with no servers left to try" do
    before do
      @cluster.servers = [@server_down_1, @server_down_2]
    end

    describe "#next_server" do
      it "uses whatever server is next" do
         @cluster.next_server.should == @server_down_1
      end
    end

    describe "#balance!" do
      it "rotates the servers" do
        @cluster.next_server.should == @server_down_1
        @cluster.balance!
        @cluster.next_server.should == @server_down_2
        @cluster.balance!
        @cluster.next_server.should == @server_down_1
      end
    end
  end

 context "with at least one server to try" do
    describe "#next_server" do
      it "gets the next server it should try" do
        @cluster.next_server.should == @server_up_1
      end
    end

    describe "#balance!" do
      it "rotates the servers it should try" do
        @cluster.next_server.should == @server_up_1
        @cluster.balance!
        @cluster.next_server.should == @server_up_2
        @cluster.balance!
        @cluster.next_server.should == @server_up_3
      end
    end
  end

  describe "#new" do
    it "creates a new cluster from an array" do
      cluster = @cluster_klass.new(["test", "test", "test"], :server_klass => @server_klass)
      cluster.servers.should == [@server_klass.new, @server_klass.new, @server_klass.new]
    end
  end
end
