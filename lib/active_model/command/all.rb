# frozen_string_literal: true

require_relative  "composite"
require_relative  "noop"
require_relative  "subject"

module ActiveModel
  module Command
    module All
      def self.included(receiver)
        receiver.send :include, Command
        receiver.send :include, Command::Composite
        receiver.send :include, Command::Noop
        receiver.send :include, Command::Subject
      end
    end
  end
end
