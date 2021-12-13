# frozen_string_literal: true

require_relative "rescuable"

module ActiveModel
  module Command
    module Composite
      module InstanceMethods
        module DeprecatedPrependMethods
          Deprecation = ActiveSupport::Deprecation.new('1.0', 'ActiveModel::Command')

          def call
            super
          rescue SubcommandFailure => error
            handle_failed_subcommand(error)
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

        private

        def call_subcommand(command)
          raise ArgumentError, "not a command" unless command.is_a?(Command)
          command.call unless command.called?
          return command.result if command.success?
          raise SubcommandFailure.new(command)
        end

        def handle_failed_subcommand(error)
          @errors.merge!(error.command.errors)
          @result = nil
        end
      end

      def self.prepended(receiver)
        receiver.send :prepend, ActiveModel::Command
        receiver.send :include, InstanceMethods
        receiver.send :prepend, InstanceMethods::DeprecatedPrependMethods
      end

      def self.included(receiver)
        receiver.send :include, ActiveModel::Command
        receiver.send :include, ActiveModel::Command::Rescuable
        receiver.send :include, InstanceMethods

        receiver.rescue_from SubcommandFailure, with: :handle_failed_subcommand
      end
    end
  end
end
