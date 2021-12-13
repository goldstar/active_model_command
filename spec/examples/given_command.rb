class GivenCommand
  include ActiveModel::Command

  attr_accessor :name

  private

  def execute
    name if given?(:name)
  end
end
