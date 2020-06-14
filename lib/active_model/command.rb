require "active_model"
require "active_model/command/version"

module ActiveModel
  module Command
    AlreadyExecuted = Class.new(RuntimeError)
    UnsupportedErrors = Class.new(RuntimeError)

    attr_reader :result

    module ClassMethods
      def call(*args, **kwargs)
        new(*args, **kwargs).call
      end
    end

    def self.prepended(base)
      base.extend ClassMethods
      base.send(:extend, ActiveModel::Translation)
      base.send(:include, ActiveModel::Validations)
    end

    def call
      fail AlreadyExecuted if called?
      fail NotImplementedError, "Define call in your Command" unless defined?(super)

      @called = true
      if !authorized?
        errors.add(:base, :unauthorized)
      elsif valid?
        @result = super
        if @result.respond_to?(:errors) && @result.errors.kind_of?(ActiveModel::Errors)
          errors.merge!(@result.errors)
        elsif @result.respond_to?(:errors)
          fail UnsupportedErrors, "Errors on result but not ActiveModel::Errors. Unable to merge."
        end
      end

      self
    end

    def success?
      called? && !failed?
    end
    alias_method :successful?, :success?

    def failed?
      called? && errors.any?
    end
    alias_method :failure?, :failed?

    def authorized?
      return super if defined?(super)
      true
    end

    private

    def called?
      @called ||= false
    end

    def command_unauthorized?
      return false if authorized?

      errors.add(:base, :unauthorized)
      return true
    end

  end
end
