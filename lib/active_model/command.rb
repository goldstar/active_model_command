require "active_model"
require "active_model/command/version"

module ActiveModel
  module Command
    AlreadyExecuted = Class.new(RuntimeError)
    UndefinedAggregateError = Class.new(StandardError)
    UnsupportedErrors = Class.new(RuntimeError)

    attr_reader :result

    module ClassMethods
      def call(*args, **kwargs)
        new(*args, **kwargs).call
      end

      attr_accessor :aggregate_name

      def aggregate(value)
        self.aggregate_name = value
        attr_accessor value
      end
    end

    def self.prepended(base)
      base.extend ClassMethods
      base.send(:include, ActiveModel::Model)
      base.send(:include, ActiveModel::Validations::Callbacks)
    end

    def initialize(*args, **kwargs)
      super(*args, **kwargs) # Either defined in class or passed up to ActiveModel::Model
      after_initialize
    end

    def call
      fail AlreadyExecuted if called?
      fail NotImplementedError, "Define call in your Command" unless defined?(super)

      @called = true
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

    def noop?
      return super if defined?(super)
      false
    end

    def after_initialize
      return super if defined?(super)
    end

    def aggregate
      return @aggregate if defined? @aggregate

      if self.class.aggregate_name.nil?
        fail UndefinedAggregateError,
          "Define aggregate name with .aggregate macro"
      end

      @aggregate = send(self.class.aggregate_name)
    end

    protected

    def changed?(attribute_name, strict=false)
      return false unless given?(attribute_name)
      return false unless aggregate.present?
      return false unless aggregate.respond_to?(attribute_name)

      original_value = aggregate.public_send(attribute_name)
      given_value = send(attribute_name)

      if given_value.kind_of?(Array) && !strict
        original_value ||= []
        given_value.sort != original_value.sort
      else
        given_value != original_value
      end
    end

    def given?(attribute_name)
      respond_to?(attribute_name) &&
      instance_variable_defined?("@#{attribute_name}")
    end

    private

    def called?
      @called ||= false
    end
  end
end
