class CompositeCommand
  prepend ActiveModel::CompositeCommand
  attr_reader :subcommands

  validates :subcommands, presence: true

  def initialize(subcommands)
    @subcommands = subcommands
  end

  def call
    subcommands.each do |subcommand|
      call_subcommand subcommand
    end

    :result
  end
end
