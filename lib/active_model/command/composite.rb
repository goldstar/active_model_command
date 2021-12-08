module ActiveModel
  module Command
    module Composite
      module InstanceMethods
        module PrependMethods
          def execute
            super
          rescue HaltedExecution => error
            handle_halted_execution(error)
          end
        end

        module DeprecatedPrependMethods
          Deprecation = ActiveSupport::Deprecation.new('1.0', 'ActiveModel::Command')

          def call
            super
          rescue HaltedExecution => error
            handle_halted_execution(error)
            self
          end

          def self.prepended(receiver)
            Deprecation.deprecation_warning <<~DEPRECATION
            Using `prepend` is being deprecated in favor of `include`. With
            this comes a change to the default features included. To preserve
            the behavior of including all features you can include
            `ActiveModel::Command::All`
            DEPRECATION

            receiver.send :include, Command::Noop
          end
        end

        def self.included(receiver)
          receiver.send :prepend, PrependMethods
        end

        private

        def handle_halted_execution(error)
          @errors.merge!(error.command.errors)
          @result = nil
        end

        def call_subcommand(command)
          raise ArgumentError, "not a command" unless command.is_a?(Command)
          command.call unless command.called?
          return command.result if command.success?
          raise HaltedExecution.new(command)
        end
      end

      def self.prepended(receiver)
        receiver.send :prepend, ActiveModel::Command
        receiver.send :include, InstanceMethods
        receiver.send :prepend, InstanceMethods::DeprecatedPrependMethods
      end

      def self.included(receiver)
        receiver.send :include, ActiveModel::Command
        receiver.send :include, InstanceMethods
      end
    end
  end
end
