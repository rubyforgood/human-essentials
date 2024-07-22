require "rails_helper"

RSpec.describe Partners::FetchPartnersToRemindNowService do
  describe ".fetch" do
    subject { described_class.new.fetch }
    let(:current_day) { 14 }
    let(:schedule_1) { IceCube::Schedule.new(Date.new(2022, 6, 1)) }
    let(:schedule_2) { IceCube::Schedule.new(Date.new(2022, 6, 1)) }
    let(:schedule_3) { IceCube::Schedule.new(Date.new(2022, 5, 1)) }
    before { travel_to(Time.zone.local(2022, 6, current_day, 1, 1, 1)) }
    after { travel_back }

    context "when there is a partner" do
      let!(:partner) { create(:partner) }
      context "that has an organization with a global reminder & deadline" do
        context "that is for today" do
          before do
            schedule_1.add_recurrence_rule IceCube::Rule.monthly.day_of_month(current_day)
            partner.organization.update(reminder_schedule: schedule_1.to_ical)
            partner.organization.update(deadline_day: current_day + 2)
          end

          it "should include that partner" do
            expect(subject).to include(partner)
          end

          context "as matched by day of the week" do
            before do
              schedule_2.add_recurrence_rule IceCube::Rule.monthly.day_of_week(tuesday: [2])
              partner.organization.update(reminder_schedule: schedule_2.to_ical)
            end
            it "should include that partner" do
              expect Time.current.day == 2
              expect(subject).to include(partner)
            end
          end

          context "but the reoccurrence rule is not for the current month" do
            before do
              schedule_3.add_recurrence_rule IceCube::Rule.monthly(2).day_of_month(current_day)
              partner.organization.update(reminder_schedule: schedule_3.to_ical)
            end

            it "should NOT include that partner" do
              expect(subject).not_to include(partner)
            end
          end

          context "but the partner is deactivated" do
            before do
              partner.deactivated!
            end

            it "should NOT include that partner" do
              expect(subject).not_to include(partner)
            end
          end

          context "and has send_reminder=false" do
            before do
              partner.update(send_reminders: false)
            end

            it "should NOT include that partner" do
              expect(subject).not_to include(partner)
            end
          end
        end

        context "that is not for today" do
          before do
            new_schedule = IceCube::Schedule.new(Date.new(2022, 6, current_day - 1)).to_ical
            partner.organization.update(reminder_schedule: new_schedule)
            partner.organization.update(deadline_day: current_day + 2)
          end

          it "should NOT include that partner" do
            expect(subject).not_to include(partner)
          end
        end

        context "AND a partner group that does have them defined" do
          before do
            schedule_1.add_recurrence_rule IceCube::Rule.monthly.day_of_month(current_day)
            schedule_2.add_recurrence_rule IceCube::Rule.monthly.day_of_month(current_day - 1)
            partner_group = create(:partner_group, reminder_schedule: schedule_1.to_ical, deadline_day: current_day + 2)
            partner_group.partners << partner

            partner.organization.update(reminder_schedule: schedule_2.to_ical)
          end

          it "should remind based on the partner group instead of the organization level reminder" do
            expect(subject).to include(partner)
          end

          context "but the partner is deactivated" do
            before do
              partner.deactivated!
            end

            it "should NOT include that partner" do
              expect(subject).not_to include(partner)
            end
          end
        end
      end

      context "that does NOT have a organization with a global reminder & deadline" do
        before do
          partner.organization.update(reminder_schedule: nil, deadline_day: nil)
        end

        context "and is a part of a partner group that does have them defined" do
          context "that is for today" do
            before do
              schedule_1.add_recurrence_rule IceCube::Rule.monthly.day_of_month(current_day)
              partner_group = create(:partner_group, reminder_schedule: schedule_1.to_ical, deadline_day: current_day + 2)
              partner_group.partners << partner
            end

            it "should include that partner" do
              expect(subject).to include(partner)
            end

            context "but the partner is deactivated" do
              before do
                partner.deactivated!
              end

              it "should NOT include that partner" do
                expect(subject).not_to include(partner)
              end
            end
          end

          context "that is not for today" do
            before do
              new_schedule = IceCube::Schedule.new(Date.new(2022, 6, current_day - 1))
              partner_group = create(:partner_group, reminder_schedule: new_schedule.to_ical, deadline_day: current_day + 2)
              partner_group.partners << partner
            end

            it "should NOT include that partner" do
              expect(subject).not_to include(partner)
            end
          end
        end
      end
    end
  end
end
