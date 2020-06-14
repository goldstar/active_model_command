class ValidatedCommand
  prepend ActiveModel::Command

  attr_reader :say

  validates :say, length: { minimum: 3 }

  def initialize(say:)
    @say = say
  end

  def call
    execute_command
  end

  private

  def execute_command
    @say
  end

end
