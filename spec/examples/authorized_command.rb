class AuthorizedCommand
  prepend ActiveModel::Command

  attr_accessor :say, :current_user

  def call
    execute_command
  end

  def authorized?
    current_user.admin?
  end

  private

  def execute_command
    say
  end
end
