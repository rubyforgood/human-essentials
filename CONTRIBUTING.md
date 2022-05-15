# Contributing

We ♥ contributors! By participating in this project, you agree to abide by the
Ruby for Good [code of conduct](https://github.com/rubyforgood/code-of-conduct).

**First:** if you're unsure or afraid of *anything*, just ask or submit the issue or pull request anyways. You won't be yelled at for giving your best effort. The worst that can happen is that you'll be politely asked to change something. We appreciate any sort of contributions, and don't want a wall of rules to get in the way of that.

## Onboarding the App
You can find detailed instructions on how to setup the app locally in [installation.md](/installation.md).
 1. Fork the repo.
 2. Clone your fork
 3. Run `cp config/database.yml.example config/database.yml` - This will copy the contents of `database.yml.example ` and put it in a new file called `database.yml`.
 4. Run `bin/setup` - we've expanded this to check for some additional setup things, including some dependencies
 5. Run `bundle exec rake db:seed` - This will set you up with a bunch of realistic data
 6. Run the specs (tests). We only take pull requests with passing tests, and it's great to know that you have a clean  slate: `bundle exec rake`.
 
## Working on an Issue
 1. Choose an issue from our [Issues List](https://github.com/rubyforgood/human-essentials/issues). Make sure that you're working on is an [open issue]–if the relevant issue doesn't exist, open it! Check the comment thread and see if anyone else has claimed it already, and if not, go ahead and let us know in the comments!
 2. The issues (the Hacktoberfest issues, at least) should be written in a way that it's pretty clear what needs to be done and what's expected. If there's anything confusing, please comment and we'll get back to you ASAP.
 3. Check out a branch
 4. Do the thing!
 5. If it makes sense to, or if the issue asks for it, please write tests as appropriate. We use RSpec.
 6. Be sure to run `rubocop -a` and make sure it runs clean (this will block merging if it doesn't)
 7. It would be wise to run the spec suite locally (`bundle exec rspec`) -- it takes 5-10 mins to run completely; Travis will run the specs regardless, but this way you don't have to wait for Travis.
 
 The seeds will create some default users in your dev environment:
 
 |      Username          | Password | Role               |
 | ---------------------- | -------- | ------------------ |
 | user_1@example.com     | password! | Regular user       |
 | user_2@example.com     | password! | Regular user       |
 | org_admin1@example.com | password! | Organization Admin |
 | org_admin2@example.com | password! | Organization Admin |
 | superadmin@example.com | password! | Super Admin        |
 
 When you start up `rails s`, you'll be able to sign in with these at whatever role-level you need to. The "1" and "2" represent different organizations. 
 
 Some things that will increase the chance that your pull request is accepted:

 - Use Rails idioms and helpers
 - Include tests that fail without your code, and pass with it (most issues require this, but not all)
 - Attention to detail with any changes to documentation that would be obviously necessary

We try to stick with "Rails Way" philosophies as much as possible, and also keep dependencies to a minimum. When in doubt, ask questions in the Issue (or better yet, in the #human-essentials Slack channel on the RubyForGood Slack!), and we'll answer them as soon as possible.

## Submitting a Pull Request
 1. Push to your fork and open a Pull Request
 2. Your PR subject should briefly describe what the PR does. Mentioning the issue number is fine, but include some words too (Good: "[12345] Donation recipient name fix", Less good: "Donations", "Donations recipients", or "12345")
 3. In the description, be sure that somewhere in the description it says "Fixes #12345", "Closes #12345" or "Resolves #12345" (where "12345" is the issue number) -- this ensures the Issue is auto-closed
 4. The PR description should describe what you're doing in it. If there's any noteworthy decisions you made or things you weren't expecting, note those in the description. We have a PR template, but you can free-form your description as long as it's thorough enough. The description should let us know what to focus on in the review.
 5. At this point you're waiting on us–we'll try to respond to your PR quickly. We may suggest some changes or improvements or alternatives.

## Test Coverage

This project uses the `simplecov` gem to generate a test coverage report. This report is generated when the tests are run (as previously mentioned, with `bundle exec rspec`). The report can then be viewed by opening `coverage/index.html` in a browser.

The most recent test coverage statistics are available online at the Code Climate web site:

* [file-by-file](https://codeclimate.com/github/rubyforgood/human-essentials/code?sort=test_coverage)
* [aggregate, including other kinds of information](https://codeclimate.com/github/rubyforgood/human-essentials)

Of the two (local and cloud), the local page is better organized and has more test coverage information. Sample screenshots can be seen in the simplecov [readme](https://github.com/colszowka/simplecov#example-output).

## Production Data

If for whatever reason you need to work with a production data set, you can follow these steps:

1. Shout out in the #human-essentials Slack channel that you need the data.
2. You will be given the credentials for the Azure account for Human Essentials. Add these to your `.env` file, along with a fourth line which is needed for `pg_restore` to work:

```
AZURE_STORAGE_ACCOUNT_NAME="diaperbase"
AZURE_STORAGE_ACCESS_KEY="****REDACTED****"
AZURE_STORAGE_CONTAINER="development"
DISABLE_DATABASE_ENVIRONMENT_CHECK=1
```
3. Run `rake fetch_latest_db`. ***Note that this will wipe away your local DB and replace it with the prod data.***
4. Once done, *remove* the last line (`DISABLE_DATABASE_ENVIRONMENT_CHECK`) from your `.env` file, as it is dangerous to keep it there.
