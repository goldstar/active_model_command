class GivenCommand
  prepend ActiveModel::Command

  attr_accessor :name

  def call
    name if given?(:name)
  end
end
