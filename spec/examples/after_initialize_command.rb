class AfterInitializeCommand
  include ActiveModel::Command

  attr_accessor :say

  def after_initialize
    @say = "#{say}!"
  end

  private

  def execute
    say
  end
end
