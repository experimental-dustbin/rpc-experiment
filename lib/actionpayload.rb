# action requests are also likely to evolve over time so encapsulate
class ActionPayload

  attr_reader :plugin, :action, :arguments

  def initialize(payload = {})
    ["plugin", "action", "arguments"].each do |e|
      if (val = payload[e]).nil?
        raise ArgumentError, "#{e} is a required argument."
      else
        instance_variable_set("@#{e}", val)
      end
    end
  end

  def serialize
    {"plugin" => @plugin, "action" => @action, "arguments" => @arguments}.to_json
  end

  def self.deserialize(serialized)
    opts = JSON.parse(serialized)
    new(opts)
  end

end
