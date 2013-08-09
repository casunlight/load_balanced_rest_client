require './lib/server.rb'

describe 'Server' do
  before do
    @downtime_algorithm = mock("LoadBalancedRestClient::Algorithms::Test", :call => 10)
    @client_klass       = mock("RestClient:Class", :new => true)
    @server             = LoadBalancedRestClient::Server.new("test", :downtime_algorithm => @downtime_algorithm,
                                                                     :client_klass => @client_klass)
  end

  describe "#mark_down!" do
    it "marks it down using #next_downtime" do
      @server.mark_down!
      @server.marked_down?.should == true
    end
  end

  describe "#stop_marking_down!" do
    it "resets marked_down_until and downtime_counter" do
      @server.mark_down_for! 100
      @server.marked_down?.should == true
      @server.stop_marking_down!
      @server.marked_down?.should == false
    end
  end

  describe "#mark_down_for!" do
    it "marks it down for X seconds" do
      @server.mark_down_for! 0.001
      @server.marked_down?.should == true
      sleep 0.001
      @server.marked_down?.should == false
    end
  end

  describe "#next_downtime" do
    it "uses the given downtime algorithm" do
      @server.next_downtime.should == 10
    end

    it "respects max" do
      @server.max_downtime = 5
      @server.next_downtime.should == 5
    end
  end
end
