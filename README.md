# Welcome Contributors!
Thanks for checking us out!

If you're new here, here are some things you should know:
 - We actively curate issues and try to make them as self-contained as possible for people new to the application; those ones are tagged "Help Wanted"
 - We're actively watching for Pull Requests and you shouldn't have to wait very long for a review. Try to make sure your build passes (`rubocop -a` is a frequent need) and that you've addressed the requirements in the issue
 - There is a wiki article called [Application Overview](https://github.com/rubyforgood/diaper/wiki/Application-Overview). It needs a tiny bit of updating, but is mostly still accurate. It will introduce you to some vocabulary and general concepts, if you find something confusing and want to find the answer on your own.
 - Check the `CONTRIBUTING.md` file for a guide on how to get started
 - This is a 100% volunteer-supported project, please be patient with your correspondence. We do handle issues and PRs with more fervor during Hacktoberfest & Conferences, but most (all?) of us have day jobs and so responses to questions / pending PRs may not be immediate. Please be patient, we'll get to you! :)

Please feel free to join us on Slack! You can sign up at https://rubyforgood.herokuapp.com We're in #diaper

The core team leads are: @edwinmak @albert @gia @sean @scott
There are numerous other folks that can chime in and answer questions -- please ask and someone will probably be there to help!

# README

[![Maintainability](https://api.codeclimate.com/v1/badges/f100428ab2af34c142b7/maintainability)](https://codeclimate.com/github/rubyforgood/diaper/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/f100428ab2af34c142b7/test_coverage)](https://codeclimate.com/github/rubyforgood/diaper/test_coverage)
[![Build Status](https://travis-ci.org/rubyforgood/diaper.svg?branch=main)](https://travis-ci.org/rubyforgood/diaper) [![View performance data on Skylight](https://badges.skylight.io/status/LrXHcxDK7Be9.svg)](https://oss.skylight.io/app/applications/LrXHcxDK7Be9)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Frubyforgood%2Fdiaper.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Frubyforgood%2Fdiaper?ref=badge_shield)
[![Knapsack Pro Parallel CI builds for RSpec tests](https://img.shields.io/badge/Knapsack%20Pro-Parallel%20%2F%20Rspec%20tests-%230074ff)](https://knapsackpro.com/dashboard/organizations/1858/projects/1295/test_suites/1835/builds?utm_campaign=organization-id-1858&amp;utm_content=test-suite-id-1835&amp;utm_medium=readme&amp;utm_source=knapsack-pro-badge&amp;utm_term=project-id-1295)

## About

This application is an inventory management system that is built to address the needs of [Diaper Banks](https://nationaldiaperbanknetwork.org/diaper-need-facts/) as directly and explicitly as possible. Diaper Banks maintain inventory, receive donations and other means of intaking diapers (and related supplies), and issue Distributions to community partner organizations. Like any non-profit, they also need to perform reports on this data, and have day-to-day operational information they need as well. This application aims to serve all those needs, as well as facilitate, wherever possible the general operations of the Diaper Bank themselves (eg. through using barcode readers, scale weighing, inventory audits).

For a general overview of the application, please see the [Application Overview](https://github.com/rubyforgood/diaper/wiki/Application-Overview) wiki article.

### Origins

This project took what we built for the [Portland Diaper Bank in 2016](https://github.com/rubyforgood/pdx_diaper) and turned it into a multitenant application, something that all diaper banks can use. We re-used models, code and other documentation where applicable as well as implemented new features and functionality requested by the prime stakeholder (PDXDB). We're super excited to have had Rachel Alston, the director of the Portland Diaper Bank, attending our event in 2017, providing guidance and giving us the best chance of success!

## Development

### Installation Instructions

The `installation.md` file ([https://github.com/rubyforgood/diaper/blob/main/installation.md](https://github.com/rubyforgood/diaper/blob/main/installation.md)) has detailed instructions for installation and configuration of an Ubuntu host to run this software. Although there is not a document for Mac OS, it may be helpful for that as well.

### Ruby Version
This app uses Ruby version 2.7.2, indicated in `/.ruby-version` and `Gemfile`, which will be auto-selected if you use a Ruby versioning manager like `rvm`, `rbenv`, or `asdf`.

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
Create a `database.yml` file on `config/` directory with your database configurations. You can also copy the existing file called `database.yml.example` as an example and just change the credentials.

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
      
## Connecting Diaper & Partner Apps Together Locally

Depending on the issues or features you decided to undertake, you may need to get both the `diaper` and `partner` app running locally. This is true if you want to build a feature that depends on code changes in both repositories.

Please follow this [guide](connecting-the-partner-and-diaper.md) to get your local environment setup properly.

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

##### Feature specs

If you need to see a feature spec run in the browser, you can use the following env variable:

```
NOT_HEADLESS=true bundle exec rspec
```

Keep in mind that you need js to be enabled. For example:

```
describe "PickupSheet", type: :feature, js: true do
```

### In-flight Pull Requests

Sometimes we want to get a PR up there and going so that other people can review it or provide feedback, but maybe it's incomplete. This is OK, but if you do it, please tag your PR with `in-progress` label so that we know not to review / merge it.

### Additional Notes

* The generated `schema.rb` file may include or omit `id: :serial` for `create table`, and `null: false` for `t.datetime`. According to Aaron, this can safely be ignored, and it is probably best to commit the schema.rb only if you have committed anything that would change the DB schema (i.e. a migration).
* If you have trouble relating to SSL libraries installing Ruby using `rvm` or `rbenv` on a Mac, you may need to add a command line option to specify the location of the SSL libraries. Assuming you are using `brew`, this will probably result in a command looking something like:

 ```rvm install 2.6.4 --with-openssl-dir=`brew --prefix openssl` ```.

### Becoming a Repo Contributor

Users that are frequent contributors and are involved in discussion (join the slack channel! :)) may be given direct Contributor access to the Repo so they can submit Pull Requests directly, instead of Forking first.

# Deployment Process
The diaper & partner application should be deployed ideally on a weekly or bi-weekly schedule. However, this depends on the amount of updates that we have merged into main. Assuming there is updates that we want to ship into deploy, this is the process we take to getting updates from our `main` branch deployed to our servers.

#### Requirements
- You will need SSH access to our servers. Access is usually only given to core maintainers of the diaper & partner projects.
- Login credentials to our [Mailchimp](https://mailchimp.com/) account

#### Tag & Release
1. You'll need to push up a tag with the proper semantic versioning. Check out the [releases](https://github.com/rubyforgood/diaper/releases) to get the correct semantic versioning tag to use. For example, if the last release was `2.1.0` and the update is a hotfix then the next one should be `2.1.1`
```sh
git tag x.y.z
git push --tags
```
2. Publish a release associated to that tag pushed up in the previous step. You can do that [here](https://github.com/rubyforgood/diaper/releases/new). Make sure to include details on what the release's updates achieves (we use this to notify our stakeholders on updates via email).

#### Deploying
Start deploying the latest update by using capistrano and specifying the correct tag
```sh
TAG=x.y.z cap production deploy
```

#### Send Update Email To Diaperbase Users
We will now want to inform the stakeholders that we've recently made a deployment and include details on what was updated. This is achieved by accessing all the user records and sending out a email via our Mailchimp account.

1. Fetch all the emails of our users by accessing our diaperbase production database
```ruby
cap production rails:console
User.all.pluck(:email) # Copy the output of this!
```
2. Use the list of the emails copied from the output from the previous step to send a update email via [Mailchimp](https://mailchimp.com/)

# Acknowledgements

Thanks to Rachel (from PDX Diaperbank) for all of her insight, support, and assistance with this application, and Sarah ( http://www.sarahkasiske.com/ ) for her wonderful design and CSS work at Ruby For Good '17!

## License
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Frubyforgood%2Fdiaper.svg?type=large)](https://app.fossa.com/projects/git%2Bgithub.com%2Frubyforgood%2Fdiaper?ref=badge_large)

