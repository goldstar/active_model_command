class TestCommand
  prepend ActiveModel::Command

  def initialize(on_call)
    @on_call = on_call
  end

  def call
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
