RSpec.describe ActiveModel::Command do
  it "has a version number" do
    expect(ActiveModel::Command::VERSION).not_to be nil
  end

  let(:command){ SuccessfulCommand.new(say: "what") }

  describe "#call" do
    it "changes success? to true" do
      expect{ command.call }.to change{ command.success? }.from(false).to(true)
    end

    it "sets the result" do
      expect{ command.call }.to change{ command.result }.from(nil).to("what")
    end

    it "doesn't have any errors", :aggregate_failures do
      errors = command.call.errors
      expect(errors).to be_empty
      expect(errors).to be_a(ActiveModel::Errors)
    end

    it "returns the command" do
      expect(command.call).to be_a(SuccessfulCommand)
    end

    context "with authorizations" do
      let(:command){ AuthorizedCommand.new(say: "who", current_user: double) }

      context "and unauthorized" do
        before do
          allow(command).to receive(:authorized?).and_return(false)
        end

        it "doesn't call #call" do # and call only calles execute_command
          expect(command).to_not receive(:execute_command)
          command.call
        end

        it "doesn't set the result" do
          expect{ command.call }.to_not change{ command.result }
        end

        it "has errors" do
          expect(command.call.errors).to be_present
        end
      end

      context "and authorized" do
        before do
          allow(command).to receive(:authorized?).and_return(true)
        end

        it "does call #call" do # and call only calles execute_command
          expect(command).to receive(:execute_command)
          command.call
        end

        it "does set the result" do
          expect{ command.call }.to change{ command.result }.to("who")
        end

        it "doesn't have errors" do
          expect(command.call.errors).to be_empty
        end
      end

      context "with validations" do
        #   validates :say, length: { minimum: 3 }
        context "and valid" do
          let(:command){ ValidatedCommand.new(say: "who") }

          it "does call #call" do # and call only calles execute_command
            expect(command).to receive(:execute_command)
            command.call
          end

          it "does set the result" do
            expect{ command.call }.to change{ command.result }.to("who")
          end

          it "doesn't have errors" do
            expect(command.call.errors).to be_empty
          end
        end

        context "and invalid" do
          let(:command){ ValidatedCommand.new(say: "me") }

          it "does not call #call" do # and call only calles execute_command
            expect(command).to_not receive(:execute_command)
            command.call
          end

          it "does not set the result" do
            expect{ command.call }.to_not change{ command.result }
          end

          it "has has errors", :aggregate_failures do
            errors = command.call.errors
            expect(errors).to be_present
            expect(errors[:say]).to be_present
          end
        end
      end

      context "the result has errors" do
        let(:command){ ValidatedResultCommand.call(name: "Jo") }

        it "returns the invalid result", :aggregate_failures do
          expect(command.result).to be_a(Person)
        end

        it "bubbles up errors to the command" do
          expect(command.errors).to be_present
        end
      end
    end

    context "when command has noop? that returns true" do
      before do
        allow(command).to receive(:noop?).and_return(true)
      end

      it "does call #call" do # and call only calles execute_command
        expect(command).to_not receive(:execute_command)
        command.call
      end

      it "is successful" do
        expect{ command.call }.to change{ command.success? }.from(false).to(true)
      end

      it "has a nil result" do
        expect{ command.call }.to_not change{ command.result }
      end
    end

    context "with an after_initialize" do
      let(:command){ AfterInitializeCommand.new(say: "Hello") }

      it "can change the attributes" do
        expect(command.say).to eq("Hello!")
      end
    end

    context "with a declared initialize command" do
      let(:command){ DeclaredInitializeCommand.new(say: "Howdy") }

      it "can initialize however it wants" do
        expect(command.call.result).to eq("Howdy!")
      end
    end

    context "#call called more than once" do
      before do
        command.call
      end

      it "raises error when called twice" do
        expect{ command.call }.to raise_error(ActiveModel::Command::AlreadyExecuted)
      end
    end
  end

  describe '.call' do
    before do
      allow(SuccessfulCommand).to receive(:new).and_return(command)
      allow(command).to receive(:call)

      SuccessfulCommand.call(say: "what")
    end

    it "initializes the command and calls #call", :aggregate_failures do
      expect(SuccessfulCommand).to have_received(:new)
      expect(command).to have_received(:call)
    end
  end

end
