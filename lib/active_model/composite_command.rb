module ActiveModel
  module CompositeCommand
    class HaltedExecution < RuntimeError
      attr_reader :command

      def initialize(command)
        @command = command
      end
    end

    def self.prepended(base)
      base.prepend ActiveModel::Command
    end

    def call
      super
    rescue HaltedExecution => error
      handle_halted_execution(error)
    end

    private

    def handle_halted_execution(error)
      @errors.merge!(error.command.errors)
      @result = nil
    end

    def call_subcommand(command)
      raise ArgumentError, "not a command" unless command.is_a?(Command)
      command.call unless command.send(:called?)
      return command.result if command.success?
      raise HaltedExecution.new(command)
    end

    def with_transaction(&block)
      ActiveRecord::Base.transaction do
        begin
          block.call
        rescue HaltedExecution => e
          handle_halted_execution(e)
          raise ActiveRecord::Rollback
        end
      end
    end
  end
end
