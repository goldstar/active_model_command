class ValidatedCommand
  prepend ActiveModel::Command

  attr_accessor :say

  validates :say, length: { minimum: 3 }

  def call
    execute_command
  end

  private

  def execute_command
    say
  end

end
