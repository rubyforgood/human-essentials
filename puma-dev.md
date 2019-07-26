After you've cloned the diaper and partner repos:

Download puma-dev: `brew install puma/puma/puma-dev` (assumes you have homebrew installed)
Install puma-dev: `puma-dev -install`

Assuming you've cloned the repos into `~/ruby/diaper` and `~/ruby/parter` link them with following:

`puma-dev link -n diaper ~/ruby/diaper`
`puma-dev link -n partner ~/ruby/partner`

You'll need to set the following environment variables for the apps to communicate as well as to log in to sidekiq and flipper.

```
PARTNER_KEY="secretpassword"
PARTNER_REGISTER_URL="https://partner.test/api/v1/partners"
PARTNER_APPROVAL_URL="https://partner.test/api/v1/approve"
PARTNER_BASE_URL="partner.test"
FLIPPER_USERNAME="admin"
FLIPPER_PASSWORD="password"
SIDEKIQ_USERNAME="admin"
SIDEKIQ_PASSWORD="password"
DIAPERBANK_KEY="secretpassword"
DIAPERBANK_ENDPOINT="https://diaper.test/api/v1"
```

In your development configuration files `development.rb` you may want to set the action_mailer config `config.action_mailer.default_url_options = { 'diaper.test' }` (or `partner.test`)

Then start up puma-dev (`puma-dev` from the command line.)

Now you can navigate to diaper.test and partner.test.

You should be good to go now!
