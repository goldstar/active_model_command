# frozen_string_literal: true

RSpec.describe ActiveModel::Command::Subject do
  describe ".command_subject macro" do
    let(:klass) {
      Class.new do
        include ActiveModel::Command
        include ActiveModel::Command::Subject
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
          include ActiveModel::Command
          include ActiveModel::Command::Subject
          command_subject :foo
        end
      }

      it { is_expected.to eq "bar" }
    end

    context "without subject defined by macro" do
      let(:klass) {
        Class.new do
          include ActiveModel::Command
          include ActiveModel::Command::Subject
          attr_accessor :foo
        end
      }

      it "fails with exception" do
        expect { subject }.to raise_error(ActiveModel::Command::UndefinedSubjectError)
      end
    end
  end
end
