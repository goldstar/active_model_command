class DeclaredInitializeCommand
  prepend ActiveModel::Command

  def call
    execute_command
  end

  def initialize(say: say)
    @say = "#{say}!"
  end

  private

  def execute_command
    @say
  end

end
