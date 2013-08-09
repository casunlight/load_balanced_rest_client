class LoadBalancedRestClient
  class Server
    attr_accessor :client, :max_downtime, :downtime_counter

    def initialize(url, opts={})
      @url                 = url
      @client              = opts[:client_klass]       || ::RestClient::Resource.new(url, opts)
      @max_downtime        = opts[:max_downtime]       || 60 * 60 #= 1 hour
      @downtime_algorithm  = opts[:downtime_algorithm] || ::LoadBalancedRestClient::Algorithms::ExponentialDowntime.new
      @downtime_counter    = 0
    end

    def mark_down_for!(time_amount)
      @downtime_counter += 1
      @marked_down_until = Time.now + with_max_downtime { time_amount }

      true
    end

    def mark_down!
      if should_try?
        downtime = next_downtime
        mark_down_for! downtime

        downtime
      else
        false
      end
    end

    def stop_marking_down!
      @marked_down_until = nil
      @downtime_counter  = 0
      true
    end

    def should_try?
      !marked_down?
    end

    def marked_down?
      !@marked_down_until.nil? && @marked_down_until > Time.now
    end

    def next_downtime
      with_max_downtime do
        @downtime_algorithm.call(@downtime_counter + 1)
      end
    end

    def to_s
      @url
    end

    private
      def with_max_downtime(&block)
        time_amount = yield
        time_amount > @max_downtime ? @max_downtime : time_amount
      end
  end
end
