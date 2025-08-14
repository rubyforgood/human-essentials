# == Schema Information
#
# Table name: partner_groups
#
#  id                           :bigint           not null, primary key
#  deadline_day                 :integer
#  name                         :string
#  reminder_day                 :integer
#  reminder_schedule_definition :string
#  send_reminders               :boolean          default(FALSE), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  organization_id              :bigint
#
RSpec.describe PartnerGroup, type: :model do
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

    # While the deadlinable concern does it's own validation of the deadline_day field and there is the
    # deadlinable_spec.rb for that, this constraint is defined in the db schema.
    describe 'deadline_day > 28' do
      it 'raises error if unmet' do
        expect { partner_group.update_column(:deadline_day, 29) }.to raise_error(ActiveRecord::StatementInvalid)
      end
    end
  end
  # rubocop:enable Rails/SkipsModelValidations

  context "Validations >" do
    it "requires a unique name within an organization" do
      expect(build(:partner_group, name: nil)).not_to be_valid
      create(:partner_group, name: "Foo")
      expect(build(:partner_group, name: "Foo")).not_to be_valid
    end

    it "does not require a unique name between organizations" do
      create(:partner, name: "Foo")
      expect(build(:partner, name: "Foo", organization: build(:organization))).to be_valid
    end

    describe "deadline_day && reminder_schedule must be defined if send_reminders=true" do
      let(:valid_reminder_schedule) {
        ReminderScheduleService.new({
          by_month_or_week: "day_of_month",
          every_nth_month: 1,
          day_of_month: 9
        }).to_ical
      }

      it "should not be valid" do
        expect(build(:partner_group, send_reminders: true)).not_to be_valid
        expect(build(:partner_group, send_reminders: true, deadline_day: 10)).not_to be_valid
        expect(build(:partner_group, send_reminders: true, reminder_schedule_definition: valid_reminder_schedule)).not_to be_valid
      end

      it "should be valid" do
        expect(build(:partner_group, send_reminders: true, deadline_day: 10, reminder_schedule_definition: valid_reminder_schedule)).to be_valid
      end
    end

    it "validates deadline_day and reminder date are different for day of month reminders" do
      partner_group = create(:partner_group, name: "Foo")
      partner_group.update(deadline_day: 10)
      partner_group.reminder_schedule.assign_attributes(by_month_or_week: "day_of_month", day_of_month: 10)
      expect(partner_group).to_not be_valid
      partner_group.reminder_schedule.assign_attributes(day_of_month: 11)
      expect(partner_group).to be_valid
    end

    it "does not validate deadline_day and reminder date are different for day of week reminders" do
      partner_group = create(:partner_group, name: "Foo")
      partner_group.update(deadline_day: 10)
      partner_group.reminder_schedule.assign_attributes(by_month_or_week: "day_of_week", day_of_week: 0, every_nth_day: 1, day_of_month: 10)
      expect(partner_group).to be_valid
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
