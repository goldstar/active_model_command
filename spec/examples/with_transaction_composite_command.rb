class WithTransactionCompositeCommand
  prepend ActiveModel::CompositeCommand
  attr_reader :subcommands

  validates :subcommands, presence: true

  def initialize(subcommands)
    @subcommands = subcommands
  end

  def call
    with_transaction do
      subcommands.each do |subcommand|
        call_subcommand subcommand
      end
    end

    :result
  end
end
