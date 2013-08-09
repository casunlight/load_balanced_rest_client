require './lib/load_balanced_rest_client'
require './spec/helper'

include SpecHelper

describe 'LoadBalancedRestClient' do
  before do
    @client = LoadBalancedRestClient.new(["localhost:8050", "localhost:8051", "localhost:8052"],
                                         :max_tries => 4, :downtime_algorithm => LoadBalancedRestClient::Algorithms::LinearDowntime.new(0.05))
  end

  context "with live servers" do
    before do
      @ws1_pid = setup_dying_web_server(:port => 8050, :max_connections => 1)
      @ws2_pid = setup_dying_web_server(:port => 8051, :max_connections => 2)
      @ws3_pid = setup_dying_web_server(:port => 8052, :max_connections => 3)

      # Sleep for a faction of a second to let the dying web servers start
      sleep(0.05)
    end

    after do
      [@ws1_pid, @ws2_pid, @ws3_pid].each {|pid| ensure_process_ended(pid) }
    end

    it "marks a server down if it fails and tries it again after its downtime expires" do
      @client.cluster.next_server.to_s.should == "localhost:8050"

      @client["test"].get
      @client.cluster.next_server.to_s.should == "localhost:8051"

      @client["test"].get
      @client.cluster.next_server.to_s.should == "localhost:8052"

      @client["test"].get
      @client.cluster.next_server.to_s.should == "localhost:8050"

      # localhost:8050 should have died and localhost:8051 be used instead,
      # making localhost:8052 the next server in [localhost:8052, localhost:8050, localhost:8051]
      #
      @client["test"].get
      @client.cluster.servers[1].marked_down?.should == true
      @client.cluster.next_server.to_s.should == "localhost:8052"

      @client["test"].get
      @client.cluster.next_server.to_s.should == "localhost:8051"

      # localhost:8051 should have died and localhost:8052 be used instead,
      # making localhost:8052 the next server in [localhost:8050, localhost:8051, localhost:8052]
      #
      @client["test"].get
      @client.cluster.servers[0].marked_down?.should == true
      @client.cluster.servers[1].marked_down?.should == true
      @client.cluster.next_server.to_s.should == "localhost:8052"

      sleep(0.2)
      #
      # All downtimes should have expired
      #
      @client.cluster.servers[0].marked_down?.should == false
      @client.cluster.servers[1].marked_down?.should == false
      @client.cluster.servers[2].marked_down?.should == false
      @client.cluster.next_server.to_s.should == "localhost:8050"
     end

    it "raises an exception when it runs out of tries" do
      expect do
        7.times { @client["test"].get }
      end.to raise_exception(LoadBalancedRestClient::LoadBalancer::MaxTriesReached)
    end
  end
end
