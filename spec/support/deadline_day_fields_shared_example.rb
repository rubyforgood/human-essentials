RSpec.shared_examples_for "deadline and reminder form" do |form_prefix, save_button, reload_record, post_form_submit|

  it "can set a reminder on a day of the month" do
    choose "Day of Month"
    fill_in "#{form_prefix}_day_of_month", with: 1
    click_on save_button

    if( post_form_submit )
      send(post_form_submit)
    end

    expect(page).to have_content("Monthly on the 1st day of the month")
  end

  it "can set a reminder on a day of the week" do
    choose "Day of the Week"
    select("First", from: "#{form_prefix}_every_nth_day" )
    select("Sunday", from: "#{form_prefix}_day_of_week" )
    click_on save_button

    if( post_form_submit )
      send(post_form_submit)
    end

    expect(page).to have_content("Monthly on the 1st Sunday")
  end

  it "can set a monthly frequency for reminders" do
    select("Every 3 month", from: "How frequently should reminders be sent (e.g. \"monthly\", \"every 3 months\", etc.)?")
    choose "Day of Month"
    fill_in "#{form_prefix}_day_of_month", with: 1
    click_on save_button

    if( post_form_submit )
      send(post_form_submit)
    end

    expect(page).to have_content("Every 3 months on the 1st day of the month")
  end

  it "can set a default deadline day" do
    fill_in "Default deadline day (final day of month to submit Requests)", with: 20
    click_on save_button

    if( post_form_submit )
      send(post_form_submit)
    end

    expect(page).to have_content("20th after the reminder")
  end

  it "warns the user if they enter the same reminder and deadline day" do
    choose "Day of Month"
    fill_in "#{form_prefix}_day_of_month", with: 15
    fill_in "Default deadline day (final day of month to submit Requests)", with: 15
    expect(page).to have_content("Reminder day cannot be the same as deadline day.")
    expect(page).to_not have_content("Your next reminder will be sent on")
    expect(page).to_not have_content("Your next deadline will be on")
  end

  it "warns the user if the reminder day is outside the range of 1 to 28" do
    choose "Day of Month"
    fill_in "#{form_prefix}_day_of_month", with: "-1"
    expect(page).to have_content("Reminder day must be between 1 and 28")
    fill_in "#{form_prefix}_day_of_month", with: "20"
    expect(page).to_not have_content("Reminder day must be between 1 and 28")
    fill_in "#{form_prefix}_day_of_month", with: "100"
    expect(page).to have_content("Reminder day must be between 1 and 28")
  end

  it "warns the user if the deadline day is outside the range of 1 to 28" do
    choose "Day of Month"
    fill_in "Default deadline day (final day of month to submit Requests)", with: "-1"
    expect(page).to have_content("Deadline day must be between 1 and 28")
    fill_in "Default deadline day (final day of month to submit Requests)", with: "20"
    expect(page).to_not have_content("Deadline day must be between 1 and 28")
    fill_in "Default deadline day (final day of month to submit Requests)", with: "100"
    expect(page).to have_content("Deadline day must be between 1 and 28")
  end

  describe "calculates the reminder and deadline dates" do

    context "when the reminder is a day of the month" do
      before do
        choose "Day of Month"
        @now = Time.zone.now
      end

      it "prior to the current date" do
        prior = @now - 1.days
        fill_in "#{form_prefix}_day_of_month", with: prior.day
        expect(page).to have_content("Your next reminder will be sent on")
        expect(page).to have_content((prior + 1.month).strftime("%b %d %Y"))
      end

      it "after the current date" do
        after = @now + 1.days
        fill_in "#{form_prefix}_day_of_month", with: after.day
        expect(page).to have_content("Your next reminder will be sent on")
        expect(page).to have_content((after).strftime("%b %d %Y"))
      end

      it "and the reminder and deadline dates are different" do
        fill_in "#{form_prefix}_day_of_month", with: @now.day + 1
        fill_in "Default deadline day (final day of month to submit Requests)", with: @now.day + 2
        expect(page).to have_content("Your next deadline will be on")
        expect(page).to have_content((@now + 2.days).strftime("%b %d %Y"))
      end
    end

    context "when the reminder is a day of the week" do
      before do
        choose "Day of the Week"
        @now = Time.zone.now
      end

      it "prior to the current day" do
        prior = @now - 1.days
        every_nth_day = ((prior.day-1)/7) + 1
        if every_nth_day > 4
          every_nth_day = -1
        end
        select(Deadlinable::NTH_TO_WORD_MAP[ every_nth_day ], from: "#{form_prefix}_every_nth_day" )
        select(Deadlinable::DAY_OF_WEEK_COLLECTION[ prior.wday ][0], from: "#{form_prefix}_day_of_week" )
        schedule = IceCube::Schedule.new()
        schedule.add_recurrence_rule( IceCube::Rule.monthly().day_of_week(prior.wday => [every_nth_day]) )
        expect(page).to have_content("Your next reminder will be sent on")
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end

      it "after the current date" do
        after = @now + 1.days
        every_nth_day = ((after.day-1)/7) + 1
        if every_nth_day > 4
          every_nth_day = -1
        end
        select(Deadlinable::NTH_TO_WORD_MAP[ every_nth_day ], from: "#{form_prefix}_every_nth_day" )
        select(Deadlinable::DAY_OF_WEEK_COLLECTION[ after.wday ][0], from: "#{form_prefix}_day_of_week" )
        schedule = IceCube::Schedule.new()
        schedule.add_recurrence_rule( IceCube::Rule.monthly().day_of_week(after.wday => [every_nth_day]) )
        expect(page).to have_content("Your next reminder will be sent on")
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end
    end
  end

  it "the deadline day form's reminder and deadline dates are consistent with the dates calculated by the FetchPartnersToRemindNowService and DeadlineService" do
    choose "Day of Month" 
    select("Every 2 month", from: "How frequently should reminders be sent (e.g. \"monthly\", \"every 3 months\", etc.)?")
    fill_in "#{form_prefix}_day_of_month", with: 14
    fill_in "Default deadline day (final day of month to submit Requests)", with: 21

    reminder_text = find('small[data-deadline-day-target="reminderText"]').text
    reminder_text.slice!("Your next reminder will be sent on ")
    reminder_text.slice!(".")
    shown_recurrence_date = Time.zone.strptime(reminder_text, "%a %b %d %Y")

    deadline_text = find('small[data-deadline-day-target="deadlineText"]').text
    deadline_text.slice!("Your next deadline will be on ")
    deadline_text.slice!(".")
    shown_deadline_date = Time.zone.strptime(deadline_text, "%a %b %d %Y")

    click_on save_button
    send(reload_record)

    expect(Partners::FetchPartnersToRemindNowService.new.fetch()).to_not include(partner)

    travel_to shown_recurrence_date

    expect(Partners::FetchPartnersToRemindNowService.new.fetch()).to include(partner)
    expect(DeadlineService.new(partner: partner).next_deadline.in_time_zone(Time.zone)).to be_within(1.second).of shown_deadline_date
  end

end