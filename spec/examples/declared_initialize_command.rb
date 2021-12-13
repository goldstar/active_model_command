class DeclaredInitializeCommand
  include ActiveModel::Command

  def initialize(say:)
    @say = "#{say}!"
  end

  private

  def execute
    @say
  end
end
