['msgpack', 'resolv', 'resolv-replace', 'socket',
 'celluloid', 'logger'].each {|e| require e}
['./dispatcher'].each {|e| require_relative e}
$logger = Logger.new(STDOUT, 'daily')
# die as soon as possible
Thread.abort_on_exception = true

module ClientRegistrationHeartbeatStateMachine
  
  def self.start
    register; establish_heartbeat; accept_rpc_requests
  end
  
  # keep trying until we successfully register
  def self.register
    begin
      @conn = Socket.tcp('localhost', 3000)
      $logger.debug "Registering."
      @conn.puts({
        "agent_dispatch_port" => 3001,
      }.to_msgpack)
    rescue Errno::ECONNREFUSED, Errno::EPIPE
      wait_period = 5
      $logger.error "Registration connection refused or broken. Retrying in #{wait_period} seconds."
      sleep wait_period; retry
    end
  end
  
  # send "OK" every X number of seconds
  def self.establish_heartbeat
    @heartbeat_thread = Thread.new do
      loop do
        $logger.debug "Heartbeat."
        begin
          @conn.puts "OK"; @conn.flush
          sleep 5
        rescue Errno::EPIPE
          $logger.error "Looks like the registry died."; break
        rescue Errno::ECONNRESET
          $logger.error "Registry closed connection on us."; break
        end
      end
      restart_heartbeat
    end
  end
  
  def self.restart_heartbeat
    $logger.info "Re-establishing heartbeat."
    register; establish_heartbeat
  end
  
  def self.accept_rpc_requests
    Thread.new do
      $logger.info "Accepting rpc requests."
      dispatcher = ::Dispatcher.new('asdf')
      Socket.tcp_server_loop(3001) do |conn|
        payload = MessagePack.unpack(conn.gets.strip)
        results = dispatcher.dispatch(payload)
        conn.puts results.to_msgpack; conn.flush
        conn.close
      end
    end
  end
  
end

ClientRegistrationHeartbeatStateMachine.start
sleep