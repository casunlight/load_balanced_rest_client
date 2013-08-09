require './lib/algorithms/exponential_downtime.rb'

describe 'Expoential Downtime' do
  before do
    @algorithm_klass = LoadBalancedRestClient::Algorithms::ExponentialDowntime
   end
  describe "#call" do
    it "calculates an exponential series" do
      @algorithm_klass.new.tap do |algorithm|
        algorithm.call(1).should == 60
        algorithm.call(2).should == 240
        algorithm.call(3).should == 540
      end
    end

    it "sets an exponent" do
      @algorithm_klass.new(3).tap do |algorithm|
        algorithm.call(1).should == 60
        algorithm.call(2).should == 480
        algorithm.call(3).should == 1620
      end
    end

    it "sets a factor" do
      @algorithm_klass.new(2, 30).tap do |algorithm|
        algorithm.call(1).should == 30
        algorithm.call(2).should == 120
        algorithm.call(3).should == 270
      end
    end
  end
end

