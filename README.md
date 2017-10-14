# README

[![Build Status](https://travis-ci.org/rubyforgood/pdx_diaper.svg?branch=master)](https://travis-ci.org/rubyforgood/pdx_diaper)

## About

This project is taking what we built for the [Portland Diaper Bank in 2016](https://github.com/rubyforgood/pdx_diaper) and turning it into a multitenant application, something that all diaper banks can use. We will be re-using models, code and other documentation where applicable as well as implementing new features and functionality requested by the stakeholder. We're super excited to have Rachel Alston, the director of the Portland Diaper Bank, attending our event in 2017 to provide guidance and give us the best chance of success!

## Ruby Version
This app uses Ruby version 2.4.2, indicated in `/.ruby-version`, which will be auto-selected if you use a Ruby versioning manager like `rvm` or `rbenv`.

## Database Configuration
This app uses PostgreSQL for all environments. You'll also need to create the `dev` and `test` databases, the app is expecting them to be named `diaper_development` and `diaper_test`, respectively. This should all be handled with `rails db:setup`.

## Login
To login, use these default credentials:

    Organization Admin
      Email: test@example.com
      Password: password

    User
      Email: test2@example.com
      Password: password

## Contributing

Please feel free to contribute! While we welcome all contributions to this app, pull-requests that address outstanding Issues *and* have appropriate test coverage for them will be strongly prioritized. In particular, addressing issues that are tagged with the next milestone should be prioritized higher.

Standard Github community processes apply -- fork the repo, make your changes, submit a pull-request with your change. Please indicate which issue it addresses in your pull-request title. Try to keep your PRs limited to one particular issue and don't make changes that are out of scope for that issue. If you notice something that needs attention but is out-of-scope, put a TODO, FIXME, or NOTE comment above it.

## Testing

This app uses RSpec, Capybara, Poltergeist, and FactoryGirl for testing. Make sure `rake spec` runs clean & green before submitting a Pull Request.

## TODOs

Before committing, please run `rake notes > TODO` in the root of the app.

Feel free to peruse the TODO file and tackle any issues found in there. These may or may not have actual issues associated with them.


# Acknowledgements

Thanks to Rachel (from PDX Diaperbank) for all of her insight, support, and assistance with this application, and Sarah ( http://www.sarahkasiske.com/ ) for her wonderful design and CSS work at Ruby For Good '17!
