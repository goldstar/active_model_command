# frozen_string_literal: true

require "active_support/rescuable"

module ActiveModel
  module Command
    # Includes ActiveSupport::Rescuable into the command and wraps
    # command execution with exception handling.
    module Rescuable
      module InstanceMethods
        module PrependMethods
          def execute
            super
          rescue => exception
            return if rescue_with_handler(exception)
            raise
          end
        end

        def self.included(receiver)
          receiver.send :prepend, PrependMethods
        end
      end

      def self.included(receiver)
        receiver.send :include, ActiveSupport::Rescuable
        receiver.send :include, InstanceMethods
      end
    end
  end
end
