# frozen_string_literal: true

RSpec.describe ActiveModel::Command::Rescuable do
  let(:command) { command_class.new }
  let(:command_class) {
    Class.new do
      include ActiveModel::Command
      include ActiveModel::Command::Rescuable

      def execute
        raise RuntimeError
      end
    end
  }

  describe "#call" do
    subject(:call) { command.call }

    context "when an exception is raised that the command rescues" do
      context "that the command rescues" do
        before do
          command_class.rescue_from(RuntimeError, with: -> (_) {})
        end

        it "handles the exception" do
          expect { call }.to_not raise_error
        end
      end

      context "that the command does not rescue" do
        it "bubbles up the exception" do
          expect { call }.to raise_error(RuntimeError)
        end
      end
    end
  end
end
