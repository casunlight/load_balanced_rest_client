require './lib/load_balancer.rb'

class TestError < StandardError; end

describe 'LoadBalancer' do
  before do
    @logger        = mock("Logger", :info => true, :warn => true, :error => true)
    @server        = mock("Server", :mark_down! => true, :stop_marking_down! => true, :should_try? => true,
                                    :next_downtime => 1, :do_stuff => true)
    @cluster       = mock("Cluster", :balance! => true, :servers_to_try => [@server], :next_server => @server)
    @load_balancer = LoadBalancedRestClient::LoadBalancer.new(@cluster, :catch => [TestError], :max_tries => 2,
                                                                        :logger => @logger)
  end

  describe "#with_server" do
    it "tries max number of times" do
      @attempts_counter = 0

      @load_balancer.with_server do |server|
        @attempts_counter += 1
        unless @already_run
          @already_run = true
          raise TestError
        end

        true
      end

      @attempts_counter.should == 2
    end

    it "throws an exception if it runs out of tries" do
      expect do
        @load_balancer.with_server { raise TestError }
      end.to raise_error(LoadBalancedRestClient::LoadBalancer::MaxTriesReached)
    end

    describe "a server" do
      context "not marked down" do
        it "calls the block" do
          @server.should_receive(:do_stuff)

          @load_balancer.with_server do |server|
            server.do_stuff
          end
        end

        context "with an exception it is configured to catch" do
          it "marks it down" do
            @server.should_receive(:mark_down!)

            @load_balancer.with_server do
              unless @already_run
                @already_run = true
                raise TestError
              end

              true
            end
          end
        end

        context "with an exception it is not configured to catch" do
          it "throws the exception immediately" do
            @attempts_counter = 0

            expect do
              @load_balancer.with_server do
                @attempts_counter += 1
                raise StandardError
              end
            end.to raise_error(StandardError)

            @attempts_counter.should == 1
          end
        end
      end

      context "marked down" do
        before do
          @server = mock("Server", :mark_down! => true, :stop_marking_down! => true, :should_try? => false,
                                   :next_downtime => 1, :do_stuff => true)
        end

        context "with an exception it is configured to catch" do
          it "does not mark the server down again" do
            @server.should_not_receive(:mark_down!)

            @load_balancer.with_server do
              unless @already_run
                @already_run = true
                raise TestError
              end

              true
            end
          end
        end
      end
    end
  end
end
