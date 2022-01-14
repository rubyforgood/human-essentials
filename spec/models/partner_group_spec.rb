# == Schema Information
#
# Table name: partner_groups
#
#  id                    :bigint           not null, primary key
#  deadline_day_of_month :integer
#  name                  :string
#  reminder_day_of_month :integer
#  send_reminders        :boolean          default(FALSE), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  organization_id       :bigint
#
RSpec.describe PartnerGroup, type: :model, skip_seed: true do
  describe 'associations' do
    it { should belong_to(:organization) }
    it { should have_many(:partners) }
    it { should have_and_belong_to_many(:item_categories) }
  end

  describe 'DB constraints' do
    let(:partner_group) { create(:partner_group) }

    # rubocop:disable Rails/SkipsModelValidations
    describe 'send_reminders IS NOT NULL' do
      it 'raises error if unmet' do
        expect { partner_group.update_column(:send_reminders, nil) }.to raise_error(ActiveRecord::StatementInvalid)
      end
    end

    describe 'deadline_day_of_month <= 28' do
      it 'raises error if unmet' do
        expect { partner_group.update_column(:deadline_day_of_month, 29) }.to raise_error(ActiveRecord::StatementInvalid)
      end
    end

    describe 'reminder_day_of_month <= 14' do
      it 'raises error if unmet' do
        expect { partner_group.update_column(:reminder_day_of_month, 15) }.to raise_error(ActiveRecord::StatementInvalid)
      end
    end

    describe 'reminder_day_of_month < deadline_day_of_month' do
      it 'raises error if unmet' do
        expect { partner_group.update_column(:deadline_day_of_month, partner_group.reminder_day_of_month - 1) }.to raise_error(ActiveRecord::StatementInvalid)
      end
    end
  end
  # rubocop:enable Rails/SkipsModelValidations

  context "Validations >" do
    it { should validate_numericality_of(:deadline_day_of_month).is_less_than_or_equal_to(28).allow_nil.only_integer }
    it { should validate_numericality_of(:reminder_day_of_month).is_less_than_or_equal_to(14).allow_nil.only_integer }

    it "must belong to an organization" do
      expect(build(:partner_group, organization_id: nil)).not_to be_valid
    end

    it "requires a unique name within an organization" do
      expect(build(:partner_group, name: nil)).not_to be_valid
      create(:partner_group, name: "Foo")
      expect(build(:partner_group, name: "Foo")).not_to be_valid
    end

    it "does not require a unique name between organizations" do
      create(:partner, name: "Foo")
      expect(build(:partner, name: "Foo", organization: build(:organization))).to be_valid
    end

    describe "deadline_day_of_month && reminder_day_of_month must be defined if send_reminders=true" do
      let(:partner_group) { build(:partner_group, send_reminders: true, deadline_day_of_month: nil, reminder_day_of_month: nil) }

      it "should not be valid" do
        expect(partner_group).not_to be_valid
      end
    end
  end
end
