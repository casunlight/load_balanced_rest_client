class LoadBalancedRestClient
  class LoadBalancer
    class MaxTriesReached < StandardError; end
    attr_accessor :cluster

    def initialize(cluster, options = {})
      @cluster                = cluster
      @human_readable_cluster = cluster.servers_to_try.join(", ")
      @exceptions_to_catch    = options[:catch]     || [Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
                                                        RestClient::ServerBrokeConnection, RestClient::RequestTimeout]
      @max_tries              = options[:max_tries] || 4
      @logger                 = options[:logger]    || Logger.new(STDOUT)
      @try_counter            = 0

      @logger.info "Setting up load balancing: #{@human_readable_cluster}"
    end

    def with_server(&req_blk)
      result = false

      until result or @try_counter == @max_tries do
        @try_counter += 1
        @server       = @cluster.next_server

        @cluster.balance!
        @logger.info "#{human_readable_request_counter}: Trying #{@server}"
        result = try_request(&req_blk)
      end

      # Reset the try counter after we're done
      @try_counter = 0

      if result
        result
      else
        @logger.error "Max tries reached"
        raise MaxTriesReached.new("Max tries reached")
      end
    end

    private
      def human_readable_request_counter
        "Request #{@try_counter}/#{@max_tries}"
      end

      def try_request(&req_blk)
        begin
          result = yield @server
          @logger.info "#{human_readable_request_counter}: #{@server} successful"
          @server.stop_marking_down!

          result
        rescue *@exceptions_to_catch => e
          @logger.info "#{human_readable_request_counter}: #{@server} threw \"#{e}\""
          if @server.should_try?
            @logger.warn "Marking server down: #{@server} for #{@server.next_downtime} seconds"
            @server.mark_down!
          end

          nil
        end
      end
  end
end
