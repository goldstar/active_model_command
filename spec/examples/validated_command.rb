class ValidatedCommand
  include ActiveModel::Command

  attr_accessor :say

  validates :say, length: { minimum: 3 }

  private

  def execute
    say
  end
end
