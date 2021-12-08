class CallbackCommand
  include ActiveModel::Command

  attr_reader :say

  before_validation :set_message

  private

  def execute
    say
  end

  def set_message
    @say = "example"
  end
end
