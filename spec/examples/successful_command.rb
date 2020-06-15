class SuccessfulCommand
  prepend ActiveModel::Command

  attr_accessor :say

  def call
    execute_command
  end

  private

  def execute_command
    say
  end

end
