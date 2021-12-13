# frozen_string_literal: true

RSpec.describe ActiveModel::Command::Noop do
  class DeprecatedNoopCommand
    prepend ActiveModel::Command

    def initialize(noop)
      @noop = noop
    end

    def call
      :result
    end

    private

    def noop?
      !!@noop
    end
  end

  class NoopCommand
    include ActiveModel::Command
    include ActiveModel::Command::Noop

    def initialize(noop)
      @noop = noop
    end

    private

    def execute
      :result
    end

    def noop?
      !!@noop
    end
  end

  describe "#call" do
    subject(:call) { command.call }

    context "when using a prepended command" do
      let(:command_class) { DeprecatedNoopCommand }

      context "and the command is a noop" do
        let(:command) { command_class.new(true) }

        it "returns the command" do
          is_expected.to eq(command)
        end

        it "has no result" do
          expect(call.result).to be_nil
        end
      end

      context "and the command is not a noop" do
        let(:command) { command_class.new(false) }

        it "returns the command" do
          is_expected.to eq(command)
        end

        it "has a result" do
          expect(call.result).to eq(:result)
        end
      end
    end

    context "when using an included command" do
      let(:command_class) { NoopCommand }

      context "and the command is a noop" do
        let(:command) { command_class.new(true) }

        it "returns the command" do
          is_expected.to eq(command)
        end

        it "has no result" do
          expect(call.result).to be_nil
        end
      end

      context "and the command is not a noop" do
        let(:command) { command_class.new(false) }

        it "returns the command" do
          is_expected.to eq(command)
        end

        it "has a result" do
          expect(call.result).to eq(:result)
        end
      end
    end
  end
end
