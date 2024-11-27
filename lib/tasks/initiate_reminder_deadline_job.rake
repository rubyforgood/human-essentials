desc "This task is called by the Heroku scheduler add-on to initiate the ReminderDeadlineJob periodically"
task :initiate_reminder_deadline_job => :environment do
  puts "Initiating the Reminder Deadline job"
  ReminderDeadlineJob.perform_now

  puts "Done!"
end
