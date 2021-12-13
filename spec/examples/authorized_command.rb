class AuthorizedCommand
  include ActiveModel::Command

  attr_accessor :say, :current_user

  def authorized?
    current_user.admin?
  end

  private

  def execute
    say
  end
end
