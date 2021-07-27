require 'sidekiq'

Sidekiq::Extensions.enable_delay!

#
# Added this conditional to run the async jobs immediately
# in development. This allows us to see the results of
# enqueuing a mailer job instantly.
#
# This effectively turns .deliver_later to .deliver_now in
# the development environment.
#
# Refer to https://makandracards.com/makandra/28125-perform-sidekiq-jobs-immediately-in-development
# for context and details.
if Rails.env.development?
  require 'sidekiq/testing'
  Sidekiq::Testing.inline!
end
