module SpecHelper
  def setup_dying_web_server(opts={})
    Process.spawn("spec/acceptance/bin/dying_web_server -p=#{opts[:port] || 8050} -m=#{opts[:max_connections] || 4}")
  end

  def ensure_process_ended(pid)
    Process.kill("HUP", pid)
  end
end
