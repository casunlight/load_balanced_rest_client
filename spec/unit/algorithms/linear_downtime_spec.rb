require './lib/algorithms/linear_downtime.rb'

describe 'Linear Downtime' do
  before do
    @algorithm_klass = LoadBalancedRestClient::Algorithms::LinearDowntime
  end

  describe "#call" do
    it "calculates a linear series" do
      @algorithm_klass.new.tap do |algorithm|
        algorithm.call(1).should == 60
        algorithm.call(2).should == 120
        algorithm.call(3).should == 180
      end
    end

    it "sets a factor" do
      @algorithm_klass.new(30).tap do |algorithm|
        algorithm.call(1).should == 30
        algorithm.call(2).should == 60
        algorithm.call(3).should == 90
      end
    end
  end
end


