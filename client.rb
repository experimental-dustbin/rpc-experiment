require 'msgpack'
require 'resolv'
require 'resolv-replace'
require 'socket'
require 'celluloid'
# die as soon as possible
Thread.abort_on_exception = true

module ClientRegistrationHeartbeatStateMachine
  def self.start
    register; establish_heartbeat; monitor_heartbeat; accept_rpc_requests
  end
  
  # keep trying until we successfully register
  def self.register
    begin
      @conn = Socket.tcp('localhost', 3000)
      puts "Registering."
      @conn.puts({
        "fqdn" => Socket.gethostbyname(Socket.gethostname).first,
        "agent_dispatch_port" => 3001
      }.to_msgpack)
    rescue Errno::ECONNREFUSED
      wait_period = 5
      puts "Registration connection refused. Retrying in #{wait_period} seconds."
      sleep wait_period
      retry
    end
  end
  
  # send "OK" every X number of seconds
  def self.establish_heartbeat
    @heartbeat_thread = Thread.new do
      loop do
        puts "Heartbeat."
        @conn.puts "OK"; @conn.flush
        sleep 5
      end
    end
  end
  
  # make sure hearbeat connection is working and take action to
  # correct the error if we can't send the heartbeat
  def self.monitor_heartbeat
    @heartbeat_monitor_thread = Thread.new do
      loop do
        puts "Monitoring heartbeat thread. No mitigating action yet."
        sleep 120
      end
    end
  end

  def self.accept_rpc_requests
    puts "Accepting rpc requests."
  end
end

ClientRegistrationHeartbeatStateMachine.start
sleep