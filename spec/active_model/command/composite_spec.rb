# frozen_string_literal: true

RSpec.describe ActiveModel::Command::Composite do
  class DeprecatedCompositeCommand
    prepend ActiveModel::CompositeCommand

    def initialize(subcommands)
      @subcommands = subcommands
    end

    def call
      @subcommands.each do |subcommand|
        call_subcommand subcommand
      end

      :result
    end
  end

  class CompositeCommand
    include ActiveModel::Command
    include ActiveModel::Command::Composite

    def initialize(subcommands)
      @subcommands = subcommands
    end

    private

    def execute
      @subcommands.each do |subcommand|
        call_subcommand subcommand
      end

      :result
    end
  end

  describe "#call" do
    subject(:call) { command.call }

    context "when using a prepended command" do
      let(:command_class) { DeprecatedCompositeCommand }

      context "and the subcommands fail" do
        let(:command) { command_class.new([TestCommand.new(:failure)]) }

        it "returns the command" do
          is_expected.to eq(command)
        end

        it "is a failure" do
          is_expected.to be_failure
        end

        it "has no result" do
          expect(call.result).to be_nil
        end
      end

      context "and the subcommands succeed" do
        let(:command) { command_class.new([TestCommand.new(:success)]) }

        it "returns the command" do
          is_expected.to eq(command)
        end

        it "is a succss" do
          is_expected.to be_success
        end

        it "has a result" do
          expect(call.result).to eq(:result)
        end
      end

      context "and the subcommands raise" do
        let(:command) { command_class.new([TestCommand.new(:raise)]) }

        it "bubbles the exception up to the caller" do
          expect { call }.to raise_error(RuntimeError)
        end

        it "has no result" do
          call
        rescue RuntimeError
          expect(command.result).to be_nil
        end
      end
    end

    context "when using an included command" do
      let(:command_class) { CompositeCommand }

      context "and the subcommands fail" do
        let(:command) { command_class.new([TestCommand.new(:failure)]) }

        it "returns the command" do
          is_expected.to eq(command)
        end

        it "is a failure" do
          is_expected.to be_failure
        end

        it "has no result" do
          expect(call.result).to be_nil
        end
      end

      context "and the subcommands succeed" do
        let(:command) { command_class.new([TestCommand.new(:success)]) }

        it "returns the command" do
          is_expected.to eq(command)
        end

        it "is a succss" do
          is_expected.to be_success
        end

        it "has a result" do
          expect(call.result).to eq(:result)
        end
      end
    end
  end
end
