# README

[![Build Status](https://travis-ci.org/rubyforgood/diaper.svg?branch=master)](https://travis-ci.org/rubyforgood/diaper) [![View performance data on Skylight](https://badges.skylight.io/status/LrXHcxDK7Be9.svg)](https://oss.skylight.io/app/applications/LrXHcxDK7Be9)

## About

This application is an inventory management system that is built to address the needs of [Diaper Banks](https://nationaldiaperbanknetwork.org/diaper-need-facts/) as directly and explicitly as possible. Diaper Banks maintain inventory, receive donations and other means of intaking diapers (and related supplies), and issue Distributions to community partner organizations. Like any non-profit, they also need to perform reports on this data, and have day-to-day operational information they need as well. This application aims to serve all those needs, as well as facilitate, wherever possible the general operations of the Diaper Bank themselves (eg. through using barcode readers, scale weighing, inventory audits).

For a general overview of the application, please see the [Application Overview](https://github.com/rubyforgood/diaper/wiki/Application-Overview) wiki article.

### Origins

This project took what we built for the [Portland Diaper Bank in 2016](https://github.com/rubyforgood/pdx_diaper) and turned it into a multitenant application, something that all diaper banks can use. We re-used models, code and other documentation where applicable as well as implemented new features and functionality requested by the prime stakeholder (PDXDB). We're super excited to have had Rachel Alston, the director of the Portland Diaper Bank, attending our event in 2017, providing guidance and giving us the best chance of success!

## Development

### Installation Instructions

The `ubuntu_installation.md` file ([https://github.com/rubyforgood/diaper/blob/master/ubuntu-installation.md](https://github.com/rubyforgood/diaper/blob/master/ubuntu-installation.md)) has detailed instructions for installation and configuration of an Ubuntu host to run this software. Although there is not a document for Mac OS, it may be helpful for that as well.

### Ruby Version
This app uses Ruby version 2.6.2, indicated in `/.ruby-version` and `Gemfile`, which will be auto-selected if you use a Ruby versioning manager like `rvm`, `rbenv`, or `asdf`.

### Yarn Installation
If you don't have Yarn installed, you can install with Homebrew on macOS `brew install yarn` or visit [https://yarnpkg.com/en/docs/install](https://yarnpkg.com/en/docs/install). Be sure to run `yarn install` after installing Yarn. NOTE: It's possible that Node version 12 may cause you problems, see issue #751. Node 10 or 11 seem to be fine.

### Create your .env with database credentials
Be sure to create a `.env` file in the root of the app that includes the following lines (change to whatever is appropriate for your system):
```
PG_USERNAME=username
PG_PASSWORD=password
```
If you're getting the error `PG::ConnectionBad: fe_sendauth: no password supplied`, it's because you have probably not done this.

### Database Configuration
This app uses PostgreSQL for all environments. You'll also need to create the `dev` and `test` databases, the app is expecting them to be named `diaper_dev` and `diaper_test`, respectively. This should all be handled with `rails db:setup`.

## Seed the database
From the root of the app, run `bundle exec rails db:seed`. This will create some initial data to use while testing the app and developing new features, including setting up the default user.

## Start the app
Run `bundle exec rails s` and browse to http://localhost:3000/

## Login
To login to the web application, use these default credentials:

    Organization Admin
      Email: org_admin1@example.com
      Password: password

    User
      Email: user_1@example.com
      Password: password

## Contributing

Please feel free to contribute! While we welcome all contributions to this app, pull-requests that address outstanding Issues *and* have appropriate test coverage for them will be strongly prioritized. In particular, addressing issues that are tagged with the next milestone should be prioritized higher.

To contribute, do these things:

 * **Identify an issue** you want to work on that is not currently assigned to anyone
 * **Assign it** to yourself (so that no one else works on it while you are)
 * (If not already a Contributor, fork the repo first)
 * **Checkout a new issue branch** -- there's no absolute requirements on this, but we encourage the branch name format `XXX-brief-description-of-feature` where `XXX` is the issue number.
 * **Do the work** -- discuss any questions on the Issues as needed (we try to be pretty good about answering questions!)
 * (If you created a new model, run `bundle exec annotate` from the root of the app)
 * **Create tests** to provide proof that your work fixes the Issue (if you need help with this, please reach out!)
 * **Commit locally**, using descriptive commit messages that acknowledge, to the best of your ability, the parts of the app that are affected by the commit.
 * **Run the tests** and make sure they run green; if they don't, fix whatever broke so that the tests pass
 * **Final commit** if any tests had to be fixed
 * **Push** up the branch
 * **Create a Pull Request** - Please indicate which issue it addresses in your pull-request title.

### Squashing Commits
Squashing your own commits before pushing is totally fine. Please don't squash other people's commits. (Everyone who contributes here deserves credit for their work! :) ). Also, consider the balance of "polluting the git log with commit messages" vs. "providing useful detail about the history of changes in the git log". If you have several (or many) smaller commits that all serve one purpose, and these can be squashed into a single commit whose message describes the thing, you're encouraged to squash.

There's no hard and fast rule here about this (for now), just use your best judgement.

### Pull Request Merging

At that point, someone will work with you on doing a code review (typically pretty minor unless it's a very significant PR). If TravisCI gives :+1: to the PR merging, we can then merge your code in; if your feature branch was in this main repository, the branch will be deleted after the PR is merged.

### Stay Scoped

Try to keep your PRs limited to one particular issue and don't make changes that are out of scope for that issue. If you notice something that needs attention but is out-of-scope, [please create a new issue.](https://github.com/rubyforgood/diaper/issues/new)

### Testing

Run all the tests with:

  `bundle exec rspec`            

This app uses RSpec, Capybara, and FactoryBot for testing. Make sure the tests run clean & green before submitting a Pull Request. If you are inexperienced in writing tests or get stuck on one, please reach out so one of us can help you. :)

The one situation where you probably don't need to write new tests is when simple re-stylings are done (ie. the page may look slightly different but the Test suite is unaffected by those changes).

Tip: If you need to skip a failing test, place `pending("Reason you are skipping the test")` into the `it` block rather than skipping with `xit`. This will allow rspec to deliver the error message without causing the test suite to fail.

example:
```ruby
  it "works!" do
    pending("Need to implement this")
    expect(my_code).to be_valid
  end
```

### In-flight Pull Requests

Sometimes we want to get a PR up there and going so that other people can review it or provide feedback, but maybe it's incomplete. This is OK, but if you do it, please tag your PR with `in-progress` label so that we know not to review / merge it.

### Additional Notes

* The generated `schema.rb` file may include or omit `id: :serial` for `create table`, and `null: false` for `t.datetime`. According to Aaron, this can safely be ignored, and it is probably best to commit the schema.rb only if you have committed anything that would change the DB schema (i.e. a migration).
* If you have trouble relating to SSL libraries installing Ruby using `rvm` or `rbenv` on a Mac, you may need to add a command line option to specify the location of the SSL libraries. Assuming you are using `brew`, this will probably result in a command looking something like:

 ```rvm install 2.6.2 --with-openssl-dir=`brew --prefix openssl` ```.

### Becoming a Repo Contributor

Users that are frequent contributors and are involved in discussion (join the slack channel! :)) may be given direct Contributor access to the Repo so they can submit Pull Requests directly, instead of Forking first.

# Acknowledgements

Thanks to Rachel (from PDX Diaperbank) for all of her insight, support, and assistance with this application, and Sarah ( http://www.sarahkasiske.com/ ) for her wonderful design and CSS work at Ruby For Good '17!
