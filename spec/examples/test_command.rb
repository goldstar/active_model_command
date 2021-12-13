class TestCommand
  include ActiveModel::Command

  def initialize(on_call)
    @on_call = on_call
  end

  private

  def execute
    case @on_call
    when :raise
      raise RuntimeError
    when :success
      return :success
    else :failure
      errors.add(:base, :failure)
    end
  end
end
