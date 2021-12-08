require_relative "command/all"

module ActiveModel
  module CompositeCommand
    def self.prepended(receiver)
      receiver.send :prepend, ActiveModel::Command
      receiver.send :prepend, ActiveModel::Command::Composite
    end
  end
end
