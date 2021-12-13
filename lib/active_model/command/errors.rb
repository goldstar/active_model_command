# frozen_string_literal: true

module ActiveModel
  module Command
    AlreadyExecuted = Class.new(RuntimeError)
    UnsupportedErrors = Class.new(RuntimeError)
    class HaltedExecution < RuntimeError
      attr_reader :command

      def initialize(command)
        @command = command
      end
    end
  end
end
