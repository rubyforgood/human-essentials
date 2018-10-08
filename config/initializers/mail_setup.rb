    ActionMailer::Base.smtp_settings = {
      :address        => 'smtp.sendgrid.net',
      :port           => '587',
      :authentication => :plain,
		  :user_name 			=> ENV['SENDGRID_USERNAME'],
		  :password 			=> ENV['SENDGRID_PASSWORD'],
      :domain         => 'diaper.app',
      :enable_starttls_auto => true
    }
