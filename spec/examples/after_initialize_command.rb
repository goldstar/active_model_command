class AfterInitializeCommand
  prepend ActiveModel::Command

  attr_accessor :say

  def call
    execute_command
  end

  def after_initialize
    @say = "#{say}!"
  end

  private

  def execute_command
    say
  end

end
