class Person
  include ActiveModel::Validations

  attr_reader :name

  validates :name, length: { minimum: 3 }

  def initialize(name:)
    @name = name
  end
end

class ValidatedResultCommand
  include ActiveModel::Command

  attr_accessor :name 

  private

  def execute
    Person.new(name: name).tap{ |p| p.valid? }
  end
end
