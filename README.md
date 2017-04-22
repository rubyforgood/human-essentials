# README

[![Build Status](https://travis-ci.org/rubyforgood/pdx_diaper.svg?branch=master)](https://travis-ci.org/rubyforgood/pdx_diaper)

## Ruby Version
This app uses Ruby version 2.3.0, indicated in `/.ruby-version`, which will be auto-selected if you use a Ruby versioning manager like `rvm` or `rbenv`.

## Database Configuration
*Note: The app currently uses SQLite3 for dev/test, but should be reconfigured to work as below, using PG.*

This app uses PostgreSQL for all environments. When you first clone this app, you will need to create a `.env` file in the root of the application, and populate it with:

```
DEV_DB_USERNAME=dev_username
DEV_DB_PASSWORD=dev_password
TEST_DB_USERNAME=test_username
TEST_DB_PASSWORD=test_password
```

You'll also need to create the `dev` and `test` databases, the app is expecting them to be named `diaper_development` and `diaper_test`, respectively.

## Contributing
Please feel free to contribute! While we welcome all contributions to this app, pull-requests that address outstanding Issues *and* have appropriate test coverage for them will be strongly prioritized. In particular, addressing issues that are tagged with the next milestone should be prioritized higher.

Standard Github community processes apply -- fork the repo, make your changes, submit a pull-request with your change. Please indicate which issue it addresses in your pull-request title.
