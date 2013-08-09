class LoadBalancedRestClient
  module Algorithms
    class ExponentialDowntime
      def initialize(exp = 2, factor = 60)
        @e = exp
        @f = factor
      end

      def call(x)
        (x ** @e) * @f
      end
    end
  end
end

