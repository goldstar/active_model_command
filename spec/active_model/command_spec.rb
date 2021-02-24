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

    context "with callbacks" do
      let(:command){ CallbackCommand.new }

      it "does call #call" do # and call only calles execute_command
        expect(command).to receive(:execute_command)
        command.call
      end

      it "does set the result" do
        expect{ command.call }.to change{ command.result }.to("example")
      end

      it "doesn't have errors" do
        expect(command.call.errors).to be_empty
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

    context "with behavior only when given attribute" do
      let(:with_given_attribute) { GivenCommand.call(name: "foo") }
      let(:without_given_attribute) { GivenCommand.call }

      it "can check if attribute was given", :aggregate_failures do
        expect(with_given_attribute.result).to eq "foo"
        expect(without_given_attribute.result).to eq nil
      end
    end

    context "with behavior only when given changed attribute for subject" do
      let(:user) {
        ChangedCommand::User.new(
          name: "foo",
          sorted_tags: ["a", "b"],
          unsorted_tags: ["a", "b"]
        )
      }
      let(:with_changed_attribute) { ChangedCommand.call(user: user, name: "bar") }
      let(:with_unchanged_attribute) { ChangedCommand.call(user: user, name: user.name) }
      let(:without_given_attribute) { ChangedCommand.call(user: user) }

      it "can check if attribute was changed", :aggregate_failures do
        expect(with_changed_attribute).to be_success
        expect(with_changed_attribute.result).to include :name_changed

        expect(with_unchanged_attribute).to be_success
        expect(with_unchanged_attribute.result).to_not include :name_changed

        expect(without_given_attribute).to be_success
        expect(without_given_attribute.result).to_not include :name_changed
      end

      context "when attribute is an array" do
        context "and order matters" do
          let(:with_appended_attribute) { ChangedCommand.call(user: user, sorted_tags: ["a", "b", "c"]) }
          let(:with_reduced_attribute) { ChangedCommand.call(user: user, sorted_tags: ["a"]) }
          let(:with_reordered_attribute) { ChangedCommand.call(user: user, sorted_tags: user.sorted_tags.reverse) }
          let(:with_unchanged_attribute) { ChangedCommand.call(user: user, sorted_tags: user.sorted_tags) }

          it "can check if attribute was changed including order" do
            expect(with_appended_attribute).to be_success
            expect(with_appended_attribute.result).to include :sorted_tags_changed

            expect(with_reduced_attribute).to be_success
            expect(with_reduced_attribute.result).to include :sorted_tags_changed

            expect(with_reordered_attribute).to be_success
            expect(with_reordered_attribute.result).to include :sorted_tags_changed

            expect(with_unchanged_attribute).to be_success
            expect(with_unchanged_attribute.result).to_not include :sorted_tags_changed
          end
        end

        context "and order doesn't matter" do
          let(:with_appended_attribute) { ChangedCommand.call(user: user, unsorted_tags: ["a", "b", "c"]) }
          let(:with_reduced_attribute) { ChangedCommand.call(user: user, unsorted_tags: ["a"]) }
          let(:with_reordered_attribute) { ChangedCommand.call(user: user, unsorted_tags: user.unsorted_tags.reverse) }
          let(:with_unchanged_attribute) { ChangedCommand.call(user: user, unsorted_tags: user.unsorted_tags) }

          it "can check if attribute was changed regardless of order" do
            expect(with_appended_attribute).to be_success
            expect(with_appended_attribute.result).to include :unsorted_tags_changed

            expect(with_reduced_attribute).to be_success
            expect(with_reduced_attribute.result).to include :unsorted_tags_changed

            expect(with_reordered_attribute).to be_success
            expect(with_reordered_attribute.result).to_not include :unsorted_tags_changed

            expect(with_unchanged_attribute).to be_success
            expect(with_unchanged_attribute.result).to_not include :unsorted_tags_changed
          end
        end
      end
    end
  end

  describe ".call" do
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

  describe ".command_subject macro" do
    let(:klass) {
      Class.new do
        prepend ActiveModel::Command
        command_subject :foo
      end
    }
    let(:instance) { klass.new }

    it "assigns .command_subject_name" do
      expect(klass.command_subject_name).to eq :foo
    end

    it "adds accessor for command_subject" do
      expect(instance).
        to respond_to(:foo).
        and respond_to(:foo=)
    end
  end

  describe "#command_subject" do
    let(:instance) { klass.new(foo: "bar") }

    subject { instance.command_subject }

    context "with subject defined by macro" do
      let(:klass) {
        Class.new do
          prepend ActiveModel::Command
          command_subject :foo
        end
      }

      it { is_expected.to eq "bar" }
    end

    context "without subject defined by macro" do
      let(:klass) {
        Class.new do
          prepend ActiveModel::Command
          attr_accessor :foo
        end
      }

      it "fails with exception" do
        expect { subject }.to raise_error(described_class::UndefinedSubjectError)
      end
    end
  end
end
