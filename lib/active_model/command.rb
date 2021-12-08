require "active_model"

require_relative "command/errors"
require_relative "command/version"

module ActiveModel
  module Command
    attr_reader :result

    module ClassMethods
      def call(*args, **kwargs)
        new(*args, **kwargs).call
      end
    end

    module InstanceMethods
      module PrependMethods
        def initialize(*args, **kwargs)
          super(*args, **kwargs)
          after_initialize if defined? after_initialize
        end
      end

      module DeprecatedPrependMethods
        Deprecation = ActiveSupport::Deprecation.new('1.0', 'ActiveModel::Command')

        def call
          fail AlreadyExecuted if called?
          fail NotImplementedError, "Define call in your Command" unless defined?(super)

          called!
          if !authorized?
            errors.add(:base, :unauthorized)
          elsif valid? && !noop?
            @result = super
            if @result.respond_to?(:errors) && @result.errors.kind_of?(ActiveModel::Errors)
              errors.merge!(@result.errors)
            elsif @result.respond_to?(:errors)
              fail UnsupportedErrors, "Errors on result but not ActiveModel::Errors. Unable to merge."
            end
          end

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

      def authorize
        errors.add(:base, :unauthorized) unless authorized?
      end

      def authorized?
        true
      end

      def call
        fail AlreadyExecuted if called?

        authorize
        return self if errors.present?

        validate
        return self if errors.present?

        @result = execute
        if @result.respond_to?(:errors) && @result.errors.kind_of?(ActiveModel::Errors)
          errors.merge!(@result.errors)
        elsif @result.respond_to?(:errors)
          fail UnsupportedErrors, "Errors on result but not ActiveModel::Errors. Unable to merge."
        end

        return self
      ensure
        called!
      end

      def called?
        !!@called
      end

      def execute
        raise NotImplementedError
      end

      def failed?
        called? && errors.any?
      end
      alias_method :failure?, :failed?

      def success?
        called? && !failed?
      end
      alias_method :successful?, :success?

      private

      def called!
        @called = true
      end

      def given?(attribute_name)
        respond_to?(attribute_name) &&
        instance_variable_defined?("@#{attribute_name}")
      end
    end

    def self.apply_to(receiver)
      receiver.send :include, ActiveModel::Model
      receiver.send :include, ActiveModel::Validations::Callbacks
      receiver.send :extend,  ClassMethods
      receiver.send :include, InstanceMethods
    end
    private_class_method :apply_to

    def self.included(receiver)
      apply_to(receiver)
    end

    def self.prepended(receiver)
      apply_to(receiver)
      receiver.send :prepend, InstanceMethods::DeprecatedPrependMethods
    end
  end
end
