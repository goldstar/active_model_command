# frozen_string_literal: true

module ActiveModel
  module Command
    AlreadyExecuted = Class.new(RuntimeError)
    UnsupportedErrors = Class.new(RuntimeError)
    class SubcommandFailure < RuntimeError
      attr_reader :command

      def initialize(command)
        @command = command
      end
    end
    HaltedExecution = Class.new(SubcommandFailure) do
      Deprecation = ActiveSupport::Deprecation.new('1.0', 'ActiveModel::Command')

      def initialize(_)
        Deprecation.deprecation_warning("use SubcommandFailure instead")
        super
      end
    end
  end
end
