# README

[![Build Status](https://travis-ci.org/rubyforgood/diaper.svg?branch=master)](https://travis-ci.org/rubyforgood/diaper) [![View performance data on Skylight](https://badges.skylight.io/status/LrXHcxDK7Be9.svg)](https://oss.skylight.io/app/applications/LrXHcxDK7Be9)

## About

This application is an inventory management system that is built to address the needs of [Diaper Banks](http://nationaldiaperbanknetwork.org/what-is-diaper-need/diaper-facts/) as directly and explicitly as possible. Diaper Banks maintain inventory, receive donations and other means of intaking diapers (and related supplies), and issue Distributions to community partner organizations. Like any non-profit, they also need to perform reports on this data, and have day-to-day operational information they need as well. This application aims to serve all those needs, as well as facilitate, wherever possible the general operations of the Diaper Bank themselves (eg. through using barcode readers, scale weighing, inventory audits).

### Closed Beta

There are currently 5 Diaper Banks, across America, that are working with our organization to use and provide critical feedback about the functionality of the application. We are grateful for their involvement, and value their input as key stakeholders.

### Origins
This project took what we built for the [Portland Diaper Bank in 2016](https://github.com/rubyforgood/pdx_diaper) and turned it into a multitenant application, something that all diaper banks can use. We re-used models, code and other documentation where applicable as well as implemented new features and functionality requested by the prime stakeholder (PDXDB). We're super excited to have had Rachel Alston, the director of the Portland Diaper Bank, attending our event in 2017, providing guidance and giving us the best chance of success!

## Development with Docker

### Requirements

- [Docker CE](https://store.docker.com/search?type=edition&offering=community)

### Caveats

Docker for Mac has some pretty poor disk sharing (volume) performance. At the time of writing, the test run is 50% slower when using Docker vs using native. Overall this shouldn't impact your development experience too badly but you should be aware.

### Postgres data

To keep data between development sessions, we create a volume to store data in ./db/data/postgres. You will need to create this directory first (./db/data is git-ignored).

`mkdir -p db/data/postgres`

Then you can set up the database with the following command.

`docker-compose run web rails db:setup`

Note: currently the seeds fail about halfway through due to the Partner integration. You can resolve this by temporarily commenting out the `DIAPER_PARTNER_URL` environment variable in ./docker-compose.yml (See [diaperpartner](https://github.com/rubyforgood/diaperpartner) for more)

### Running the app

Start the application with `docker-compose up web` and then visit [http://localhost:3000](http://localhost:3000)

### Running tests

Simply run `docker-compose run test rails spec`.

## Development without Docker

### Ruby Version
This app uses Ruby version 2.5.1, indicated in `/.ruby-version`, which will be auto-selected if you use a Ruby versioning manager like `rvm` or `rbenv`.

### Database Configuration
This app uses PostgreSQL for all environments. You'll also need to create the `dev` and `test` databases, the app is expecting them to be named `diaper_development` and `diaper_test`, respectively. This should all be handled with `rails db:setup`.

### Create your .env with database credentials
Be sure to create a `.env` file in the root of the app that includes the following lines (change to whatever is appropriate for your system):
```
PG_USERNAME=username
PG_PASSWORD=password
```
If you're getting the error `PG::ConnectionBad: fe_sendauth: no password supplied`, it's because you have probably not done this.

## Seed the database
From the root of the app, run `bundle exec rake db:seed`. This will create some initial data to use while testing the app and developing new features, including setting up the default user.

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

Try to keep your PRs limited to one particular issue and don't make changes that are out of scope for that issue. If you notice something that needs attention but is out-of-scope, put a TODO, FIXME, or NOTE comment above it

### Testing

If you are using Docker you may run the tests with `docker-compose run test`, otherwise run `bundle exec rake spec`.

This app uses RSpec, Capybara, and FactoryBot for testing. Make sure the tests run clean & green before submitting a Pull Request. If you are inexperienced in writing tests or get stuck on one, please reach out so one of us can help you. :)

The one situation where you probably don't need to write new tests is when simple re-stylings are done (ie. the page may look slightly different but the Test suite is unaffected by those changes).

### TODOs

Before committing, please run `rake notes > TODO` in the root of the app.

Feel free to peruse the TODO file and tackle any issues found in there. These may or may not have actual issues associated with them. If they do not have actual issues, use `TODO-Brief-Description` as the the branch naming scheme, instead; similar changes for commit message.

### In-flight Pull Requests

Sometimes we want to get a PR up there and going so that other people can review it or provide feedback, but maybe it's incomplete. This is OK, but if you do it, please tag your PR with `in-progress` label so that we know not to review / merge it.

### Becoming a Repo Contributor

Users that are frequent contributors and are involved in discussion (join the slack channel! :)) may be given direct Contributor access to the Repo so they can submit Pull Requests directly, instead of Forking first.

# Acknowledgements

Thanks to Rachel (from PDX Diaperbank) for all of her insight, support, and assistance with this application, and Sarah ( http://www.sarahkasiske.com/ ) for her wonderful design and CSS work at Ruby For Good '17!
