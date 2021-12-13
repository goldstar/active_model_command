module ActiveModel
  module Command
    module Noop
      module InstanceMethods
        module PrependMethods
          def execute
            super unless noop?
          end
        end

        def self.included(receiver)
          receiver.send :prepend, PrependMethods
        end

        def noop?
          false
        end
      end
      
      def self.included(receiver)
        receiver.send :include, InstanceMethods
      end
    end
  end
end
