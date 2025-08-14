# The reminder day (the #{form_prefix}_reminder_schedule_service_day_of_month field ) has to be less than or equal to 28.
# These functions are implemented to calculate dates prior or after a given date that do not fall on a
# date with a day greater than 28.
# It is recommended to use these functions to calculate, from now, inputs for the reminder day and deadline day fields if
# your test cares about the text created by the deadline_day_controller.js controller as there isn't an easy way to spoof
# the current time in the test browser and different behavior could occur if the test is run on different days.
def safe_add_days(date, num)
  result = date + num.days
  if result.day > 28
    result = result.change({day: 1 + num})
    result += 1.month
  end
  result
end

def safe_subtract_days(date, num)
  result = date - num.days
  if result.day > 28
    result = result.change({day: 28 - num})
    result -= 1.month
  end
  result
end

RSpec.shared_examples_for "deadline and reminder form" do |form_prefix, save_button, post_form_submit|
  it "can set a reminder on a day of the month" do
    choose "Day of Month"
    fill_in "#{form_prefix}_reminder_schedule_service_day_of_month", with: 1
    fill_in "Deadline day in reminder email", with: 10
    click_on save_button

    if post_form_submit
      send(post_form_submit)
    end

    expect(page).to have_content("Monthly on the 1st day of the month")
  end

  it "can set a reminder on a day of the week" do
    choose "Day of the Week"
    select("First", from: "#{form_prefix}_reminder_schedule_service_every_nth_day")
    select("Sunday", from: "#{form_prefix}_reminder_schedule_service_day_of_week")
    fill_in "Deadline day in reminder email", with: 10
    click_on save_button

    if post_form_submit
      send(post_form_submit)
    end

    expect(page).to have_content("Monthly on the 1st Sunday")
  end

  it "warns the user if they enter an invalid reminder or deadline day", :aggregate_failures do
    choose "Day of Month"
    fill_in "#{form_prefix}_reminder_schedule_service_day_of_month", with: 15
    fill_in "Deadline day in reminder email", with: 15
    expect(page).to have_content("Reminder day cannot be the same as deadline day.")
    expect(page).to_not have_content("Your next reminder date is")
    expect(page).to_not have_content("The deadline on your next reminder email will be")

    fill_in "#{form_prefix}_reminder_schedule_service_day_of_month", with: "-1"
    expect(page).to have_content("Reminder day must be between 1 and 28")
    fill_in "#{form_prefix}_reminder_schedule_service_day_of_month", with: "20"
    expect(page).to_not have_content("Reminder day must be between 1 and 28")
    fill_in "#{form_prefix}_reminder_schedule_service_day_of_month", with: "100"
    expect(page).to have_content("Reminder day must be between 1 and 28")
    fill_in "Deadline day in reminder email", with: "-1"
    expect(page).to have_content("Deadline day must be between 1 and 28")
    fill_in "Deadline day in reminder email", with: "20"
    expect(page).to_not have_content("Deadline day must be between 1 and 28")
    fill_in "Deadline day in reminder email", with: "100"
    expect(page).to have_content("Reminder day cannot be the same as deadline day.")
    fill_in "Deadline day in reminder email", with: "101"
    expect(page).to have_content("Deadline day must be between 1 and 28")
  end

  describe "reported reminder and deadline dates" do
    context "when the reminder is a day of the month" do
      before do
        choose "Day of Month"
        @now = safe_add_days(Time.zone.now, 0)
      end

      it "calculates the reminder and deadline dates", :aggregate_failures do
        # Prior
        reminder_date = safe_subtract_days(@now, 2)
        fill_in "#{form_prefix}_reminder_schedule_service_day_of_month", with: reminder_date.day
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_month(reminder_date.day))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))

        # After
        reminder_date = safe_add_days(@now, 2)
        fill_in "#{form_prefix}_reminder_schedule_service_day_of_month", with: reminder_date.day
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_month(reminder_date.day))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))

        # Same
        fill_in "#{form_prefix}_reminder_schedule_service_day_of_month", with: @now.day
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_month(@now.day))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end
    end

    context "when the reminder is a day of the week" do
      before do
        choose "Day of the Week"
        @now = safe_add_days(Time.zone.now, 0)
      end

      def calc_every_nth_day(target_date)
        every_nth_day = ((target_date.day - 1) / 7) + 1
        if every_nth_day > 4
          every_nth_day = -1
        end
        every_nth_day
      end

      it "calculates the reminder and deadline dates", :aggregate_failures do
        # Prior
        target_date = @now - 2.days
        every_nth_day = calc_every_nth_day(target_date)
        select(ReminderScheduleService::NTH_TO_WORD_MAP[every_nth_day], from: "#{form_prefix}_reminder_schedule_service_every_nth_day")
        select(ReminderScheduleService::DAY_OF_WEEK_COLLECTION[target_date.wday][0], from: "#{form_prefix}_reminder_schedule_service_day_of_week")
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_week(target_date.wday => [every_nth_day]))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))

        # After
        target_date = @now + 2.days
        every_nth_day = calc_every_nth_day(target_date)
        select(ReminderScheduleService::NTH_TO_WORD_MAP[every_nth_day], from: "#{form_prefix}_reminder_schedule_service_every_nth_day")
        select(ReminderScheduleService::DAY_OF_WEEK_COLLECTION[target_date.wday][0], from: "#{form_prefix}_reminder_schedule_service_day_of_week")
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_week(target_date.wday => [every_nth_day]))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))

        # Same
        target_date = @now
        every_nth_day = calc_every_nth_day(target_date)
        select(ReminderScheduleService::NTH_TO_WORD_MAP[every_nth_day], from: "#{form_prefix}_reminder_schedule_service_every_nth_day")
        select(ReminderScheduleService::DAY_OF_WEEK_COLLECTION[target_date.wday][0], from: "#{form_prefix}_reminder_schedule_service_day_of_week")
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_week(target_date.wday => [every_nth_day]))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))

        # End of the month
        target_date = @now.end_of_month
        every_nth_day = calc_every_nth_day(target_date)
        select(ReminderScheduleService::NTH_TO_WORD_MAP[every_nth_day], from: "#{form_prefix}_reminder_schedule_service_every_nth_day")
        select(ReminderScheduleService::DAY_OF_WEEK_COLLECTION[target_date.wday][0], from: "#{form_prefix}_reminder_schedule_service_day_of_week")
        expect(page).to have_content("Your next reminder date is")
        schedule = IceCube::Schedule.new(@now)
        schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_week(target_date.wday => [every_nth_day]))
        expect(page).to have_content(schedule.next_occurrence.strftime("%b %d %Y"))
      end
    end
  end
end
