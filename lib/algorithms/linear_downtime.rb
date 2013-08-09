class LoadBalancedRestClient
  module Algorithms
    class LinearDowntime
      def initialize(factor = 60)
        @f = factor
      end

      def call(x)
        x * @f
      end
    end
  end
end
