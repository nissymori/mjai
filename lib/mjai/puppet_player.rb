$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)
require "player"


module Mjai
    
    class PuppetPlayer < Player
        
        def respond_to_action(action)
          return nil
        end
        
    end
    
end
