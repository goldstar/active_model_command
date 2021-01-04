class CallbackCommand
  prepend ActiveModel::Command

  attr_reader :say

  before_validation :set_message

  def call
    execute_command
  end

  private

  def execute_command
    say
  end

  def set_message
    @say = "example"
  end
end
