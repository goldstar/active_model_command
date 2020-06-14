class AuthorizedCommand
  prepend ActiveModel::Command

  def initialize(say:, current_user:)
    @say = say
    @current_user = current_user
  end

  def call
    execute_command
  end

  def authorized?
    @current_user.admin?
  end

  private

  def execute_command
    @say
  end
end
