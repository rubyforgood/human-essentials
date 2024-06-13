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

# Contributing workflow

1. **Identify an unassigned issue**.
2. **Assign it** to avoid duplicated efforts (or request assignment by adding a comment).
3. **Fork the repo** if you're not a contributor yet.
4. **Create a new branch** for the issue using the format `XXX-brief-description-of-feature`, where `XXX` is the issue number.
5. **Commit fixes locally** using descriptive messages that indicate the affected parts of the app
6. If you create a new model run `bundle exec annotate` from the root of the app
7. **Create RSpec tests** to validate that your work fixes the issue (if you need help with this, please reach out!) 
8. **Run the tests** and make sure all tests pass successfully; if any fail, fix the issues causing the failures.
9. **Final commit** if tests needed fixing.
10. **Squash smaller commits.**
11. **Push** up the branch
12. **Create a pull request** and indicate the addressed issue in the title

## Issues  
All work is organized by issues.  
[Find issues here.](https://github.com/rubyforgood/human-essentials/issues)  

If you would like to contribute, please ask for an issue to be assigned to you.  
If you would like to contribute something that is not represented by an issue, please make an issue and assign yourself.  
Only take multiple issues if they are related and you can solve all of them at the same time with the same pull request.  

### Pull Requests  
If you are so inclined, you can open a draft PR as you continue to work on it.

1. Follow [the setup guide](https://github.com/rubyforgood/human-essentials#%EF%B8%8F-getting-started) to get the project working locally.

1. Run the tests. We only take pull requests with passing tests, and it's great to know that you have a clean slate: `bundle exec rspec`

1. Add a test for your change. If you are adding functionality or fixing a  bug, you should add a test!

1. Run linters and fix any linting errors they brings up.  
   - `bin/lint`

1. Push to your branch/fork and submit a pull request. Include the issue number (ex. `Resolves #1`) in the PR description. This will ensure the issue gets closed automatically when the pull request gets merged.

## 🤝 Contributing Guidelines

Please feel free to contribute! While we welcome all contributions to this app, pull-requests that address outstanding Issues *and* have appropriate test coverage for them will be strongly prioritized. In particular, addressing issues that are tagged with the next milestone should be prioritized higher.