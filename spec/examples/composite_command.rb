require "active_model/command/composite"

class CompositeCommand
  include ActiveModel::Command
  include ActiveModel::Command::Composite
  attr_reader :subcommands

  validates :subcommands, presence: true

  def initialize(subcommands)
    @subcommands = subcommands
  end

  private
  
  def execute
    subcommands.each do |subcommand|
      call_subcommand subcommand
    end

    :result
  end
end
