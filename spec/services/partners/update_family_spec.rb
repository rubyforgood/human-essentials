RSpec.describe Partners::UpdateFamily do
  describe "#call" do
    subject { described_class.archive(family) }
    let(:family) { FactoryBot.create(:partners_family) }
    let!(:child1) { FactoryBot.create(:partners_child, family: family) }
    let!(:child2) { FactoryBot.create(:partners_child, family: family) }

    context "when family has children" do
      it "archives the family and its children" do
        expect {
          subject
        }.to change { family.reload.archived }.from(false).to(true)
          .and change { child1.reload.archived }.from(false).to(true)
          .and change { child2.reload.archived }.from(false).to(true)
      end
    end

    context "when an error occurs during archiving" do
      it "does not archive the family or its children and adds error to the service" do
        allow(family.children).to receive(:update_all).and_raise(StandardError)

        initial_family_archived = family.archived
        initial_children_archived = family.children.pluck(:archived)
        initial_errors = subject.errors.dup

        expect(family.reload.archived).to eq(initial_family_archived)
        expect(family.children.pluck(:archived)).to eq(initial_children_archived)
        expect(subject.errors.full_messages).to eq(initial_errors.full_messages)
      end
    end
  end
end
