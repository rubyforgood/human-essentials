# Welcome Contributors! 👋
We ♥ contributors! By participating in this project, you agree to abide by the Ruby for Good [code of conduct](https://github.com/rubyforgood/human-essentials/blob/main/code-of-conduct.md).

If you're new here, here are some things you should know:
- Issues tagged "Help Wanted" are self-contained and great for new contributors
- Pull Requests are reviewed within a week or so
- Ensure your build passes linting and tests and addresses the issue requirements
- This project relies entirely on volunteers, so please be patient with communication

# Communication 💬
If you have any questions about an issue, comment on the issue, open a new issue, or ask in [the RubyForGood slack](https://join.slack.com/t/rubyforgood/shared_invite/zt-2k5ezv241-Ia2Iac3amxDS8CuhOr69ZA). human-essentials has a `#human-essentials` channel in the Slack. Our channel in slack also contains a zoom link for office hours every day office hours are held.  
  
Many helpful members are available to answer your questions. Just ask, and someone will be there to help you!

You won't be yelled at for giving your best effort. The worst that can happen is that you'll be politely asked to change something. We appreciate any sort of contributions, and don't want a wall of rules to get in the way of that.

# Getting Started
## Local Environment 🛠️
1. Install Ruby
   - Install the version specified in [`.ruby-version`](.ruby-version).
   - Visit the [Install Ruby on Rails](https://gorails.com/setup/osx/12-monterey) guide by GoRails for Ubuntu, Windows, and macOSX setup. ⚠️ Follow only the Installing Ruby step, as our project setup differs ⚠️ It is highly recommended you use a ruby version manager such as [rbenv](https://github.com/rbenv/rbenv), [asdf](https://asdf-vm.com/), or [rvm](https://rvm.io/).
   - Verify that your Ruby installation works by running `ruby -v`.
2. Install Postgres
   - Follow one of these guides: [MacOSX](https://www.digitalocean.com/community/tutorials/how-to-use-postgresql-with-your-ruby-on-rails-application-on-macos), [Ubuntu](https://www.digitalocean.com/community/tutorials/how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-18-04).
     - Do you develop on Windows? We'd love to hear (and for you to submit a PR explaining) how you do it. 🙏🏻
   - Create a `database.yml` file on `config/` directory with your database configurations. You can also copy the existing files called [`database.yml.example`](config/database.yml.example) and [`.env.example`](.env.example) and change the credentials.
3. Clone the project and switch to its directory
4. Run `bin/setup`
5. Run `bin/start` and visit http://localhost:3000/ to see the human essentials page.
6. Log in as a sample user with the default [credentials](#credentials).
 
## Credentials
 These credentials also work for [staging](https://staging.humanessentials.app/):

<details>
  <summary> Super Users 🦸🏽‍♀️ </summary>

  ```
    username: superadmin@example.com
    password: password!
  ```
</details>

<details>
  <summary> Bank Users 🏦 </summary>

  ```
    Organization Admin
       Email: org_admin1@example.com
    Password: password!

    User
    Email: user_1@example.com
    Password: password!
  ```
</details>

<details>
  <summary> Partner Users 👥 </summary>

  ```
    Verified Partner
    Email: verified@example.com
    Password: password!

    Invited Partner
    Email: invited@pawneehomeless.com
    Password: password!

    Unverified Partner
    Email: unverified@pawneepregnancy.com
    Password: password!

    Recertification Required Partner
    Email: recertification_required@example.com
    Password: password!
  ```
</details>

## Codespaces - EXPERIMENTAL 🛠️

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/rubyforgood/human-essentials/tree/main?quickstart=1)

1. Follow the link above or follow instructions to [create a new Codespace.](https://docs.github.com/en/codespaces/developing-in-a-codespace/creating-a-codespace-for-a-repository); You can use the web editor, or even better open the Codespace in VSCode
2. Wait for the container to start. This will take a few (10-15) minutes since Ruby needs to be installed, the database needs to be created, and the `bin/setup` script needs to run
3. Run `bin/start` and visit the URL that pops in VSCode up to see the human essentials page
4. Login as a sample user with the default [credentials](#credentials).

## Troubleshooting 👷🏼‍♀️

Please let us know by opening up an issue! We have many new contributors come through and it is likely what you experienced will happen to them as well.

- *"My RBENV installation didn't work!"* - The rbenv repository provides a [rbenv-doctor script](https://github.com/rbenv/rbenv-installer#rbenv-doctor) to verify the installation and check if a ruby version is installed

# 🤝 Contributing workflow

1. **Identify an unassigned issue**. Read more [here](#issues) about how to pick a good issue.
2. **Assign it** to avoid duplicated efforts (or request assignment by adding a comment).
3. **Fork the repo** if you're not a contributor yet. Read about becoming a contributor [here](#becoming-a-repo-contributor).
4. **Create a new branch** for the issue using the format `XXX-brief-description-of-feature`, where `XXX` is the issue number.
5. **Commit fixes locally** using descriptive messages that indicate the affected parts of the app. Read debugging tips [here](#debugging).
6. If you create a new model run `bundle exec annotate` from the root of the app
7. **Create RSpec tests** to validate that your work fixes the issue (if you need help with this, please reach out!). Read guidelines [here](#writing-browsersystemfeature-testsspecs).
8. **Run the tests** and make sure all tests pass successfully; if any fail, fix the issues causing the failures. Read guidelines [here](#test-before-submitting-pull-requests).
9. **Final commit** if tests needed fixing.
10. **Squash smaller commits.** Read guidelines [here](#squashing-commits).
11. **Push** up the branch
12. **Create a pull request** and indicate the addressed issue (e.g. `Resolves #1`) in the title, which will ensure the issue gets closed automatically when the pull request gets merged. Read PR guidelines [here](#pull-requests).
13. **Code review**: At this point, someone will work with you on doing a code review. The automated tests will run linting, rspec, and brakeman tests. If the automated tests give :+1: to the PR merging, we can then do any additional (staging) testing as needed. 

14. **Merge**: Finally if all looks good the core team will merge your code in; if your feature branch was in this main repository, the branch will be deleted after the PR is merged. 

15. Deploys are currently done about once a week! Read the deployment process [here](#deployment-process).

## Issues  
Please feel free to contribute! While we welcome all contributions to this app, pull-requests that address outstanding Issues *and* have appropriate test coverage for them will be strongly prioritized. In particular, addressing issues that are tagged with the next milestone should be prioritized higher.

All work is organized by issues.  
[Find issues here.](https://github.com/rubyforgood/human-essentials/issues)  

If you would like to contribute, please ask for an issue to be assigned to you.  
If you would like to contribute something that is not represented by an issue, please make an issue and assign yourself.  
Only take multiple issues if they are related and you can solve all of them at the same time with the same pull request.  

## Becoming a Repo Contributor

Users that are frequent contributors and are involved in discussion (join the slack channel! :)) may be given direct Contributor access to the Repo so they can submit Pull Requests directly instead of Forking first.

## Debugging
If starting server directly, via `rail s` or `rail console`, or built-in debugger in RubyMine, or running `bundle exec rspec path/to/spec.rb:line_no`, then you can use `binding.pry` to debug. Drop the pry where you want the execution to pause.

If starting via Procfile with `bin/start`, then drop a ``binding.remote_pry`` into the line where you want execution to pause at. Then run ``pry-remote`` in the terminal to connect to it.
https://github.com/Mon-Ouie/pry-remote

## Squashing commits

Consider the balance of "polluting the git log with commit messages" vs. "providing useful detail about the history of changes in the git log". If you have several smaller commits that serve a one purpose, you are encouraged to squash them into a single commit. There's no hard and fast rule here about this (for now), just use your best judgement. Please don't squash other people's commits. Everyone who contributes here deserves credit for their work! :)

Only commit the schema.rb only if you have committed anything that would change the DB schema (i.e. a migration).

## Pull Requests  
### Stay scoped

Try to keep your PRs limited to one particular issue, and don't make changes that are out of scope for that issue. If you notice something that needs attention but is out of scope, please [create a new issue](https://github.com/rubyforgood/human-essentials/issues/new).

### In-flight pull requests

If you are so inclined, you can open a draft PR as you continue to work on it. Sometimes we want to get a PR up there and going so that other people can review it or provide feedback, but maybe it's incomplete. This is OK, but if you do it, please tag your PR with `in-progress` label so that we know not to review / merge it.

## Tests 🧪
### Writing Browser/System/Feature Tests/Specs

Add a test for your change. If you are adding functionality or fixing a  bug, you should add a test!

If you are inexperienced in writing tests or get stuck on one, please reach out for help :). You probably don't need to write new tests when simple re-stylings are done (ie. the page may look slightly different but the Test suite is unaffected by those changes).

If you need to see a browser/system spec run in the browser, you can use the following env variable:

```
NOT_HEADLESS=true bundle exec rspec
```

We've added [magic_test](https://github.com/bullet-train-co/magic_test) which makes creating browser specs much easier. It allows you to record actions on the browser running the specs and easily paste them into the spec. You can do this by adding `magic_test` within your system spec:
```rb
 it "does some browser stuff" do
   magic_test
 end
```
and run the spec using this command: `MAGIC_TEST=1 NOT_HEADLESS=true bundle exec rspec <path_to_spec>`

**See videos of it in action [here](https://twitter.com/andrewculver/status/1366062684802846721)**

### Test before submitting pull requests
- Before submitting a pull request, run all tests and rake tasks with `bundle exec rake` and run lints with `bin/lint`. Fix any broken tests and lints before submitting a pull request.
- You can run all the tests without rake tasks with `bundle exec rspec`
- You can run a single test with `bundle exec rspec {path_to_test_name}_spec.rb` or on a specific line by appending `:LineNumber`
- If you need to skip a failing test, place `pending("Reason you are skipping the test")` into the `it` block rather than skipping with `xit`. This will allow rspec to deliver the error message without causing the test suite to fail.

```ruby
  it "works!" do
    pending("Need to implement this")
    expect(my_code).to be_valid
  end
```
