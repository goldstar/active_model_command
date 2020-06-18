RSpec.describe ActiveModel::CompositeCommand do
  def success_command
    TestCommand.new(:success)
  end

  def failure_command
    TestCommand.new(:failure)
  end

  def exception_command
    TestCommand.new(:raise)
  end

  subject(:command) { CompositeCommand.new(subcommands) }
  let(:errors) { command.errors }

  describe "#call" do
    context "when all subcommands are a success" do
      before do
        command.call
      end

      let(:command) { CompositeCommand.new([success_command])}

      it { is_expected.to be_success }

      it "has a result" do
        expect(command.result).to eq(:result)
      end
    end

    context "when a subcommand fails" do
      before do
        command.call
      end

      let(:command) { CompositeCommand.new([failure_command])}

      it { is_expected.to be_failure }

      it "adds errors" do
        expect(errors[:base]).to include(/failure/)
      end

      it "does not have a result" do
        expect(command.result).to be_nil
      end
    end

    context "when a subcommand raises an exception" do
      let(:command) { CompositeCommand.new([exception_command])}

      it "bubbles the exception up to the caller" do
        expect { command.call }.to raise_error(RuntimeError)
      end

      it "does not have a result" do
        command.call
      rescue RuntimeError
        expect(command.result).to be_nil
      end
    end

    context "when a subcommand is a composite" do
      let(:command) { CompositeCommand.new([composite]) }

      context "which is a success" do
        let(:composite) { CompositeCommand.new([success_command]) }

        before do
          command.call
        end

        let(:subcommands) { [success_composite] }

        it { is_expected.to be_success }

        it "has a result" do
          expect(command.result).to eq(:result)
        end
      end

      context "which is a failure" do
        before do
          command.call
        end

        let(:composite) { CompositeCommand.new([failure_command]) }

        it "adds errors" do
          expect(errors[:base]).to include(/failure/)
        end

        it "does not have a result" do
          expect(command.result).to be_nil
        end
      end

      context "which raises" do
        let(:composite) { CompositeCommand.new([exception_command]) }

        it "bubbles the exception up to the caller" do
          expect { command.call }.to raise_error(RuntimeError)
        end

        it "does not have a result" do
          command.call
        rescue RuntimeError
          expect(command.result).to be_nil
        end
      end
    end
  end
end
