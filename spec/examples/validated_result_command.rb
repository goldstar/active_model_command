class Person
  include ActiveModel::Validations

  attr_reader :name

  validates :name, length: { minimum: 3 }

  def initialize(name:)
    @name = name
  end
end

class ValidatedResultCommand
  prepend ActiveModel::Command

  def initialize(name:)
    @name = name
  end

  def call
    execute_command
  end

  private

  def execute_command
    Person.new(name: @name).tap{ |p| p.valid? }
  end

end
