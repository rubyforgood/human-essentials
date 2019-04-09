# lib/tasks/factory_bot.rake
namespace :factory_bot do
  desc "Verify that all FactoryBot factories are valid"
  task lint: :environment do
    if Rails.env.test?
      Rails.logger.info "-~=> [PRE-LINT] Destroying all Base Items ... "
      BaseItem.delete_all
      DatabaseCleaner.cleaning do
        Rails.logger.info "///////////////////////////////////////////////"
        Rails.logger.info "////////////////// LINTING ////////////////////"
        Rails.logger.info "///////////////////////////////////////////////"

        FactoryBot.lint

        Rails.logger.info "///////////////////////////////////////////////"
        Rails.logger.info "////////////////// END LINT ///////////////////"
        Rails.logger.info "///////////////////////////////////////////////"
      end
    else
      system("bundle exec rake factory_bot:lint RAILS_ENV='test'")
      fail if $?.exitstatus.nonzero?
    end
  end
end