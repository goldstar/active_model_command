class NoopCommand
  prepend ActiveModel::Command

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
