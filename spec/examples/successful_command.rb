require "active_model/command/noop"

class SuccessfulCommand
  include ActiveModel::Command
  include ActiveModel::Command::Noop

  attr_accessor :say

  private

  def execute
    say
  end

end
