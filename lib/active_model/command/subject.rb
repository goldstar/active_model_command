module ActiveModel
  module Command
    UndefinedSubjectError = Class.new(StandardError)

    module Subject
      module ClassMethods
        attr_accessor :command_subject_name

        def command_subject(value)
          self.command_subject_name = value
          attr_accessor value
        end
      end

      module InstanceMethods
        def command_subject
          return @command_subject if defined? @command_subject

          if self.class.command_subject_name.nil?
            fail UndefinedSubjectError,
              "Define subject name with .command_subject macro"
          end

          @command_subject = send(self.class.command_subject_name)
        end

        def changed?(attribute_name, strict=false)
          return false unless given?(attribute_name)
          return false unless command_subject.present?
          return false unless command_subject.respond_to?(attribute_name)

          original_value = command_subject.public_send(attribute_name)
          given_value = send(attribute_name)

          if given_value.kind_of?(Array) && !strict
            original_value ||= []
            given_value.sort != original_value.sort
          else
            given_value != original_value
          end
        end
      end
      
      def self.included(receiver)
        receiver.send :extend,  ClassMethods
        receiver.send :include, InstanceMethods
      end
    end
  end
end
