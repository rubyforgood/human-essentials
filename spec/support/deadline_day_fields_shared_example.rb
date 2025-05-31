RSpec.shared_examples_for "deadline and reminder form" do |form_prefix, save_button, reload_record, post_form_submit|
  it "can set a reminder on a day of the month" do
    choose "Day of Month"
    fill_in "#{form_prefix}_day_of_month", with: 1
    fill_in "Default deadline day (final day of month to submit Requests)", with: 10
    click_on save_button

    if post_form_submit
      send(post_form_submit)
    end

    expect(page).to have_content("Monthly on the 1st day of the month")
  end

  it "can set a reminder on a day of the week" do
    choose "Day of the Week"
    select("First", from: "#{form_prefix}_every_nth_day")
    select("Sunday", from: "#{form_prefix}_day_of_week")
    fill_in "Default deadline day (final day of month to submit Requests)", with: 10
    click_on save_button

    if post_form_submit
      send(post_form_submit)
    end

    expect(page).to have_content("Monthly on the 1st Sunday")
  end

  it "can set a monthly frequency for reminders" do
    select("Every 3 month", from: "How frequently should reminders be sent (e.g. \"monthly\", \"every 3 months\", etc.)?")
    choose "Day of Month"
    fill_in "#{form_prefix}_day_of_month", with: 1
    fill_in "Default deadline day (final day of month to submit Requests)", with: 10
    click_on save_button

    if post_form_submit
      send(post_form_submit)
    end

    expect(page).to have_content("Every 3 months on the 1st day of the month")
  end

  it "can set a default deadline day" do
    fill_in "Default deadline day (final day of month to submit Requests)", with: 20
    click_on save_button

    if post_form_submit
      send(post_form_submit)
    end

    expect(page).to have_content("20th after the reminder")
  end

  it "warns the user if they enter the same reminder and deadline day" do
    choose "Day of Month"
    fill_in "#{form_prefix}_day_of_month", with: 15
    fill_in "Default deadline day (final day of month to submit Requests)", with: 15
    expect(page).to have_content("Reminder day cannot be the same as deadline day.")
    expect(page).to_not have_content("Your next reminder date is")
    expect(page).to_not have_content("Your next deadline date is")
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

      it "prior to the current date and start date" do
        fill_in "#{form_prefix}_day_of_month", with: (@now - 2.days).day
        fill_in "#{form_prefix}_start_date", with: (@now - 1.day).strftime("%Y-%m-%d")
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now - 1.day)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_month((@now - 2.days).day))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))

        fill_in "#{form_prefix}_start_date", with: (@now + 1.day).strftime("%Y-%m-%d")
        schedule = IceCube::Schedule.new(@now + 1.day)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_month((@now - 2.days).day))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))

        fill_in "#{form_prefix}_start_date", with: @now.strftime("%Y-%m-%d")
        schedule = IceCube::Schedule.new(@now)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_month((@now - 2.days).day))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end

      it "after the current date and start date" do
        fill_in "#{form_prefix}_day_of_month", with: (@now + 2.days).day
        fill_in "#{form_prefix}_start_date", with: (@now - 1.day).strftime("%Y-%m-%d")
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now - 1.day)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_month((@now + 2.days).day))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))

        fill_in "#{form_prefix}_start_date", with: (@now + 1.day).strftime("%Y-%m-%d")
        schedule = IceCube::Schedule.new(@now + 1.day)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_month((@now + 2.days).day))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))

        fill_in "#{form_prefix}_start_date", with: @now.strftime("%Y-%m-%d")
        schedule = IceCube::Schedule.new(@now)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_month((@now + 2.days).day))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end

      it "after the start date and prior to the current date" do
        fill_in "#{form_prefix}_start_date", with: (@now - 2.days).strftime("%Y-%m-%d")
        fill_in "#{form_prefix}_day_of_month", with: (@now - 1.day).day
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now - 2.days)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_month((@now - 1.day).day))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end

      it "after the current date and prior to the start date" do
        fill_in "#{form_prefix}_start_date", with: (@now + 2.days).strftime("%Y-%m-%d")
        fill_in "#{form_prefix}_day_of_month", with: (@now + 1.day).day
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now + 2.days)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_month((@now + 1.day).day))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end

      it "same as the current date and prior to the start date" do
        fill_in "#{form_prefix}_start_date", with: (@now + 1.day).strftime("%Y-%m-%d")
        fill_in "#{form_prefix}_day_of_month", with: @now.day
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now + 1.day)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_month(@now.day))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end

      it "same as the current date and after the start date" do
        fill_in "#{form_prefix}_start_date", with: (@now - 1.day).strftime("%Y-%m-%d")
        fill_in "#{form_prefix}_day_of_month", with: @now.day
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now - 1.day)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_month(@now.day))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end

      it "same as the start date and prior to the current date" do
        fill_in "#{form_prefix}_start_date", with: (@now - 1.day).strftime("%Y-%m-%d")
        fill_in "#{form_prefix}_day_of_month", with: (@now - 1.day).day
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now - 1.day)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_month((@now - 1.day).day))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end

      it "same as the start date and after the current date" do
        fill_in "#{form_prefix}_start_date", with: (@now + 1.day).strftime("%Y-%m-%d")
        fill_in "#{form_prefix}_day_of_month", with: (@now + 1.day).day
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now + 1.day)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_month((@now + 1.day).day))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end

      it "same as the start and current date" do
        fill_in "#{form_prefix}_start_date", with: @now.strftime("%Y-%m-%d")
        fill_in "#{form_prefix}_day_of_month", with: @now.day
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_month(@now.day))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end
    end

    context "when the reminder is a day of the week" do
      before do
        choose "Day of the Week"
        @now = Time.zone.now
      end

      def calc_every_nth_day(target_date)
        every_nth_day = ((target_date.day - 1) / 7) + 1
        if every_nth_day > 4
          every_nth_day = -1
        end
        every_nth_day
      end

      it "prior to the current date and start date" do
        target_date = @now - 2.days
        every_nth_day = calc_every_nth_day(target_date)
        select(Deadlinable::NTH_TO_WORD_MAP[every_nth_day], from: "#{form_prefix}_every_nth_day")
        select(Deadlinable::DAY_OF_WEEK_COLLECTION[target_date.wday][0], from: "#{form_prefix}_day_of_week")

        fill_in "#{form_prefix}_start_date", with: (@now - 1.day).strftime("%Y-%m-%d")
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now - 1.day)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_week(target_date.wday => [every_nth_day]))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))

        fill_in "#{form_prefix}_start_date", with: (@now + 1.day).strftime("%Y-%m-%d")
        schedule = IceCube::Schedule.new(@now + 1.day)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_week(target_date.wday => [every_nth_day]))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))

        fill_in "#{form_prefix}_start_date", with: @now.strftime("%Y-%m-%d")
        schedule = IceCube::Schedule.new(@now)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_week(target_date.wday => [every_nth_day]))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end

      it "after the current date and start date" do
        target_date = @now + 2.days
        every_nth_day = calc_every_nth_day(target_date)
        select(Deadlinable::NTH_TO_WORD_MAP[every_nth_day], from: "#{form_prefix}_every_nth_day")
        select(Deadlinable::DAY_OF_WEEK_COLLECTION[target_date.wday][0], from: "#{form_prefix}_day_of_week")

        fill_in "#{form_prefix}_start_date", with: (@now - 1.day).strftime("%Y-%m-%d")
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now - 1.day)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_week(target_date.wday => [every_nth_day]))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))

        fill_in "#{form_prefix}_start_date", with: (@now + 1.day).strftime("%Y-%m-%d")
        schedule = IceCube::Schedule.new(@now + 1.day)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_week(target_date.wday => [every_nth_day]))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))

        fill_in "#{form_prefix}_start_date", with: @now.strftime("%Y-%m-%d")
        schedule = IceCube::Schedule.new(@now)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_week(target_date.wday => [every_nth_day]))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end

      it "after the start date and prior to the current date" do
        target_date = @now - 1.day
        every_nth_day = calc_every_nth_day(target_date)
        select(Deadlinable::NTH_TO_WORD_MAP[every_nth_day], from: "#{form_prefix}_every_nth_day")
        select(Deadlinable::DAY_OF_WEEK_COLLECTION[target_date.wday][0], from: "#{form_prefix}_day_of_week")

        fill_in "#{form_prefix}_start_date", with: (@now - 2.days).strftime("%Y-%m-%d")
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now - 2.days)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_week(target_date.wday => [every_nth_day]))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end

      it "after the current date and prior to the start date" do
        target_date = @now + 1.day
        every_nth_day = calc_every_nth_day(target_date)
        select(Deadlinable::NTH_TO_WORD_MAP[every_nth_day], from: "#{form_prefix}_every_nth_day")
        select(Deadlinable::DAY_OF_WEEK_COLLECTION[target_date.wday][0], from: "#{form_prefix}_day_of_week")

        fill_in "#{form_prefix}_start_date", with: (@now + 2.days).strftime("%Y-%m-%d")
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now + 2.days)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_week(target_date.wday => [every_nth_day]))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end

      it "same as the current date and prior to the start date" do
        target_date = @now
        every_nth_day = calc_every_nth_day(target_date)
        select(Deadlinable::NTH_TO_WORD_MAP[every_nth_day], from: "#{form_prefix}_every_nth_day")
        select(Deadlinable::DAY_OF_WEEK_COLLECTION[target_date.wday][0], from: "#{form_prefix}_day_of_week")

        fill_in "#{form_prefix}_start_date", with: (@now + 1.day).strftime("%Y-%m-%d")
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now + 1.day)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_week(target_date.wday => [every_nth_day]))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end

      it "same as the current date and after the start date" do
        target_date = @now
        every_nth_day = calc_every_nth_day(target_date)
        select(Deadlinable::NTH_TO_WORD_MAP[every_nth_day], from: "#{form_prefix}_every_nth_day")
        select(Deadlinable::DAY_OF_WEEK_COLLECTION[target_date.wday][0], from: "#{form_prefix}_day_of_week")

        fill_in "#{form_prefix}_start_date", with: (@now - 1.day).strftime("%Y-%m-%d")
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now - 1.day)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_week(target_date.wday => [every_nth_day]))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end

      it "same as the start date and prior to the current date" do
        target_date = @now - 1.day
        every_nth_day = calc_every_nth_day(target_date)
        select(Deadlinable::NTH_TO_WORD_MAP[every_nth_day], from: "#{form_prefix}_every_nth_day")
        select(Deadlinable::DAY_OF_WEEK_COLLECTION[target_date.wday][0], from: "#{form_prefix}_day_of_week")

        fill_in "#{form_prefix}_start_date", with: target_date.strftime("%Y-%m-%d")
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(target_date)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_week(target_date.wday => [every_nth_day]))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end

      it "same as the start date and after the current date" do
        target_date = @now + 1.day
        every_nth_day = calc_every_nth_day(target_date)
        select(Deadlinable::NTH_TO_WORD_MAP[every_nth_day], from: "#{form_prefix}_every_nth_day")
        select(Deadlinable::DAY_OF_WEEK_COLLECTION[target_date.wday][0], from: "#{form_prefix}_day_of_week")

        fill_in "#{form_prefix}_start_date", with: target_date.strftime("%Y-%m-%d")
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(target_date)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_week(target_date.wday => [every_nth_day]))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end

      it "same as the start and current date" do
        target_date = @now
        every_nth_day = calc_every_nth_day(target_date)
        select(Deadlinable::NTH_TO_WORD_MAP[every_nth_day], from: "#{form_prefix}_every_nth_day")
        select(Deadlinable::DAY_OF_WEEK_COLLECTION[target_date.wday][0], from: "#{form_prefix}_day_of_week")

        fill_in "#{form_prefix}_start_date", with: target_date.strftime("%Y-%m-%d")
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(target_date)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_week(target_date.wday => [every_nth_day]))
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
    reminder_text.slice!("Your next reminder date is ")
    reminder_text.slice!(".")
    shown_recurrence_date = Time.zone.strptime(reminder_text, "%a %b %d %Y")

    deadline_text = find('small[data-deadline-day-target="deadlineText"]').text
    deadline_text.slice!("Your next deadline date is ")
    deadline_text.slice!(".")
    shown_deadline_date = Time.zone.strptime(deadline_text, "%a %b %d %Y")

    click_on save_button
    send(reload_record)

    expect(Partners::FetchPartnersToRemindNowService.new.fetch).to_not include(partner)

    travel_to shown_recurrence_date

    expect(Partners::FetchPartnersToRemindNowService.new.fetch).to include(partner)
    expect(DeadlineService.new(partner: partner).next_deadline.in_time_zone(Time.zone)).to be_within(1.second).of shown_deadline_date
  end
end
