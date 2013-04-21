puts __FILE__
if ARGV[0] == 'agent_node'
  require_relative '../lib/agent_server/agent'
elsif ARGV[0] == 'registration_node'
  require_relative '../lib/registration_server/registration_server'
else
  puts "Please specify the type of node to start: agent_node | registration_node."
  puts "e.g. java -jar rpc.jar [agent_node|registration_node] [options]"
end
