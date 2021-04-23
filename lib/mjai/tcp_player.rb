require "timeout"
$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)
require "player"
require "action"
require "validation_error"


module Mjai
    
    class TCPPlayer < Player
        
        TIMEOUT_SEC = 60
        
        def initialize(socket, name)
          super()
          @socket = socket
          self.name = name
        end
        
        def respond_to_action(action)
          
          begin
            
            puts("server -> player %d\t%s" % [self.id, action.to_json()])
            @socket.puts(action.to_json())
            line = nil
            Timeout.timeout(TIMEOUT_SEC) do
              line = @socket.gets()
            end
            if line
              puts("server <- player %d\t%s" % [self.id, line])
              return Action.from_json(line.chomp(), self.game)
            else
              puts("server :  Player %d has disconnected." % self.id)
              return Action.new({:type => :none})
            end
            
          rescue Timeout::Error
            return create_action({
                :type => :error,
                :message => "Timeout. No response in %d sec." % TIMEOUT_SEC,
            })
          rescue JSON::ParserError => ex
            return create_action({
                :type => :error,
                :message => "JSON syntax error: %s" % ex.message,
            })
          rescue ValidationError => ex
            return create_action({
                :type => :error,
                :message => ex.message,
            })
            
          end
          
        end
        
        def close()
          @socket.close()
        end
        
    end
    
end
