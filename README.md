# Human Essentials 

<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-100-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->
[![View performance data on Skylight](https://badges.skylight.io/status/LrXHcxDK7Be9.svg)](https://oss.skylight.io/app/applications/LrXHcxDK7Be9)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Frubyforgood%2Fdiaper.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Frubyforgood%2Fdiaper?ref=badge_shield)
[![Knapsack Pro Parallel CI builds for RSpec tests](https://img.shields.io/badge/Knapsack%20Pro-Parallel%20%2F%20Rspec%20tests-%230074ff)](https://knapsackpro.com/dashboard/organizations/1858/projects/1295/test_suites/1835/builds?utm_campaign=organization-id-1858&amp;utm_content=test-suite-id-1835&amp;utm_medium=readme&amp;utm_source=knapsack-pro-badge&amp;utm_term=project-id-1295)

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
This app uses PostgreSQL for all environments. You'll also need to create the `dev` and `test` databases, the app is expecting them to be named `diaper_dev`, `diaper_test`, `partner_dev`, and `partner_test` respectively. This should all be handled with `rails db:setup`.
Create a `database.yml` file on `config/` directory with your database configurations. You can also copy the existing file called `database.yml.example` as an example and just change the credentials.

### Seed the database
From the root of the app, run `bundle exec rails db:seed`. This will create some initial data to use while testing the app and developing new features, including setting up the default user.

### Start the app
Run `bundle exec rails server` or `bundle exec bin/start` (recommended since it runs webpacker in the background!) and browse to http://localhost:3000/

### Login
To login to the web application, use these default credentials:

**Diaperbase Users**
```
Organization Admin
  Email: org_admin1@example.com
  Password: password

User
  Email: user_1@example.com
  Password: password
```

**Partnerbase Users**
```
Verified Partner
  Email: verified@example.com
  Password: password

Invited Partner
  Email: invited@pawneehomelss.com
  Password: password
  
Unverified Partner
  Email: unverified@pawneepregnancy.com
  Password: password
  
Recertification Required Partner
  Email: recertification_required@example.com
  Password: password
```

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

### Writing Tests/Specs

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

### On Writing Browser/System/Feature Specs

If you need to see a browser/system spec run in the browser, you can use the following env variable:

```
NOT_HEADLESS=true bundle exec rspec
```

##### Use magic_test to simplify browser/system/feature spec writing
We've added [magic_test](https://github.com/bullet-train-co/magic_test) which makes creating browser specs much easier. It does this by giving you the ability to record actions on the browser running the specs and easily paste them into the spec.

For example you can do this by adding `magic_test` within your system spec:
```rb
 it "does some browser stuff" do
   magic_test
 end
```
and run the spec using this command:
```
MAGIC_TEST=1 NOT_HEADLESS=true bundle exec rspec <path_to_spec>
```

**See videos of it in action [here](https://twitter.com/andrewculver/status/1366062684802846721)**

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
emails = User.all.pluck(:email) 
puts "Email Address\n" + emails.join("\n") # Copy this output
```
2. Use the list of the emails copied from the output from the previous step to send a update audience via [Mailchimp](https://mailchimp.com/). Go to Audience > Manage Audience > Import Contacts and select "Copy and paste" option. Then paste the output of step 1. Complete the subsequent steps.

3. Draft the email and send it with updates.

# Acknowledgements

Thanks to Rachel (from PDX Diaperbank) for all of her insight, support, and assistance with this application, and Sarah ( http://www.sarahkasiske.com/ ) for her wonderful design and CSS work at Ruby For Good '17!

## License
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Frubyforgood%2Fdiaper.svg?type=large)](https://app.fossa.com/projects/git%2Bgithub.com%2Frubyforgood%2Fdiaper?ref=badge_large)


## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://github.com/edwinthinks"><img src="https://avatars.githubusercontent.com/u/11335191?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Edwin Mak</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=edwinthinks" title="Code">💻</a> <a href="#projectManagement-edwinthinks" title="Project Management">📆</a> <a href="#infra-edwinthinks" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="#ideas-edwinthinks" title="Ideas, Planning, & Feedback">🤔</a> <a href="#question-edwinthinks" title="Answering Questions">💬</a> <a href="#security-edwinthinks" title="Security">🛡️</a></td>
    <td align="center"><a href="https://rubyforgood.org/"><img src="https://avatars.githubusercontent.com/u/667909?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Sean Marcia</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=seanmarcia" title="Code">💻</a> <a href="#business-seanmarcia" title="Business development">💼</a> <a href="#financial-seanmarcia" title="Financial">💵</a> <a href="#fundingFinding-seanmarcia" title="Funding Finding">🔍</a> <a href="#eventOrganizing-seanmarcia" title="Event Organizing">📋</a></td>
    <td align="center"><a href="https://armahillo.dev/"><img src="https://avatars.githubusercontent.com/u/502363?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Aaron H</b></sub></a><br /><a href="#projectManagement-armahillo" title="Project Management">📆</a> <a href="https://github.com/rubyforgood/human-essentials/commits?author=armahillo" title="Code">💻</a></td>
    <td align="center"><a href="https://gitlab.com/IlinDmitry"><img src="https://avatars.githubusercontent.com/u/13395396?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Dmitry</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=IlinDmitry" title="Code">💻</a></td>
    <td align="center"><a href="http://adambachman.org/"><img src="https://avatars.githubusercontent.com/u/13002?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Adam Bachman</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=abachman" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/jcavena"><img src="https://avatars.githubusercontent.com/u/200333?v=4?s=100" width="100px;" alt=""/><br /><sub><b>JC Avena</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=jcavena" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/mdworken"><img src="https://avatars.githubusercontent.com/u/31595784?v=4?s=100" width="100px;" alt=""/><br /><sub><b>mdworken</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=mdworken" title="Code">💻</a> <a href="#projectManagement-mdworken" title="Project Management">📆</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://github.com/mlpinit"><img src="https://avatars.githubusercontent.com/u/1443346?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Marius Pop</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=mlpinit" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/ejuten"><img src="https://avatars.githubusercontent.com/u/10624016?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Elayne</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=ejuten" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/duaimei"><img src="https://avatars.githubusercontent.com/u/7873934?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Amy Detwiler</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=duaimei" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/designbygia"><img src="https://avatars.githubusercontent.com/u/56228717?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Gia</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=designbygia" title="Code">💻</a></td>
    <td align="center"><a href="https://medium.com/@adewusi"><img src="https://avatars.githubusercontent.com/u/42121379?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Amina Adewusi</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=Nirvikalpa108" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/albertchae"><img src="https://avatars.githubusercontent.com/u/217050?v=4?s=100" width="100px;" alt=""/><br /><sub><b>albertchae</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=albertchae" title="Code">💻</a> <a href="#ideas-albertchae" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://github.com/cattywampus"><img src="https://avatars.githubusercontent.com/u/1625840?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Keith Walters</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=cattywampus" title="Code">💻</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://southard.dev/"><img src="https://avatars.githubusercontent.com/u/7292?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Chase Southard</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=chaserx" title="Code">💻</a></td>
    <td align="center"><a href="http://thelackthereof.org/"><img src="https://avatars.githubusercontent.com/u/8642?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Brock Wilcox</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=awwaiid" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/danquill"><img src="https://avatars.githubusercontent.com/u/16866776?v=4?s=100" width="100px;" alt=""/><br /><sub><b>danquill</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=danquill" title="Code">💻</a></td>
    <td align="center"><a href="http://www.bbs-software.com/"><img src="https://avatars.githubusercontent.com/u/28410?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Keith Bennett</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=keithrbennett" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/benreyn"><img src="https://avatars.githubusercontent.com/u/11561578?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Benjamin Reynolds</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=benreyn" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/jtu0"><img src="https://avatars.githubusercontent.com/u/4042423?v=4?s=100" width="100px;" alt=""/><br /><sub><b>jtu0</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=jtu0" title="Code">💻</a></td>
    <td align="center"><a href="https://www.linkedin.com/in/juarezlustosa"><img src="https://avatars.githubusercontent.com/u/505372?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Juarez Lustosa</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=JuarezLustosa" title="Code">💻</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://github.com/JulienAmoros"><img src="https://avatars.githubusercontent.com/u/17905578?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Julien A.</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=JulienAmoros" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/EmersonManabuAraki"><img src="https://avatars.githubusercontent.com/u/26900611?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Emerson Manabu Araki</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=EmersonManabuAraki" title="Code">💻</a></td>
    <td align="center"><a href="http://powerhrg.com/"><img src="https://avatars.githubusercontent.com/u/167131?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Ben Klang</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=bklang" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/karolina-benitez"><img src="https://avatars.githubusercontent.com/u/28552912?v=4?s=100" width="100px;" alt=""/><br /><sub><b>karolina</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=karolina-benitez" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/joshcano"><img src="https://avatars.githubusercontent.com/u/5419597?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Josh Cano</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=joshcano" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/sbpipb"><img src="https://avatars.githubusercontent.com/u/2242652?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Julian Macmang</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=sbpipb" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/PhilipDeFraties"><img src="https://avatars.githubusercontent.com/u/65036872?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Philip DeFraties</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=PhilipDeFraties" title="Code">💻</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://github.com/GabrielRMuller"><img src="https://avatars.githubusercontent.com/u/33486409?v=4?s=100" width="100px;" alt=""/><br /><sub><b>GabrielRMuller</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=GabrielRMuller" title="Code">💻</a></td>
    <td align="center"><a href="https://luchiago.github.io/"><img src="https://avatars.githubusercontent.com/u/30028621?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Lucas Hiago</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=luchiago" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/chiefkikio"><img src="https://avatars.githubusercontent.com/u/3259878?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Lanya Butler</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=chiefkikio" title="Code">💻</a></td>
    <td align="center"><a href="https://edumoreira1506.github.io/blog"><img src="https://avatars.githubusercontent.com/u/49662698?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Eduardo Moreira</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=edumoreira1506" title="Code">💻</a></td>
    <td align="center"><a href="https://aliciabarrett.dev/"><img src="https://avatars.githubusercontent.com/u/13841769?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Alicia Barrett</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=Aliciawyse" title="Code">💻</a></td>
    <td align="center"><a href="http://www.forchaengineering.com/"><img src="https://avatars.githubusercontent.com/u/4605789?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Bob Forcha</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=bobforcha" title="Code">💻</a></td>
    <td align="center"><a href="http://willmurphyscode.net/"><img src="https://avatars.githubusercontent.com/u/12529630?v=4?s=100" width="100px;" alt=""/><br /><sub><b>William Murphy</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=willmurphyscode" title="Code">💻</a></td>
  </tr>
  <tr>
    <td align="center"><a href="http://www.katelovescode.com/"><img src="https://avatars.githubusercontent.com/u/8364647?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Kate Donaldson</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=katelovescode" title="Code">💻</a></td>
    <td align="center"><a href="http://matthewdodds.com/"><img src="https://avatars.githubusercontent.com/u/1717864?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Matthew Russell Dodds</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=MatthewRDodds" title="Code">💻</a></td>
    <td align="center"><a href="http://www.daydreamsinruby.com/"><img src="https://avatars.githubusercontent.com/u/2354079?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Allison McMillan</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=asheren" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/a-jean"><img src="https://avatars.githubusercontent.com/u/9901121?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Ashley Jean</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=a-jean" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/jeduardo824"><img src="https://avatars.githubusercontent.com/u/27960597?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Eduardo Alencar</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=jeduardo824" title="Code">💻</a></td>
    <td align="center"><a href="http://www.thomashart.me/"><img src="https://avatars.githubusercontent.com/u/3099915?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Thomas Hart</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=myrridin" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/viamin"><img src="https://avatars.githubusercontent.com/u/260794?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Bart Agapinan</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=viamin" title="Code">💻</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://github.com/NiquiCara"><img src="https://avatars.githubusercontent.com/u/45127691?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Monique</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=NiquiCara" title="Code">💻</a></td>
    <td align="center"><a href="http://valerie.codes/"><img src="https://avatars.githubusercontent.com/u/5439589?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Valerie Woolard</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=valeriecodes" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/zak-kay"><img src="https://avatars.githubusercontent.com/u/79330383?v=4?s=100" width="100px;" alt=""/><br /><sub><b>zak-kay</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=zak-kay" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/jjlahatte"><img src="https://avatars.githubusercontent.com/u/35351407?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Jason LaHatte</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=jjlahatte" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/davetapley"><img src="https://avatars.githubusercontent.com/u/48232?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Dave Tapley</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=davetapley" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/Megchan"><img src="https://avatars.githubusercontent.com/u/11429067?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Meghan</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=Megchan" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/dropkickfish"><img src="https://avatars.githubusercontent.com/u/33702528?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Andy Thackray</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=dropkickfish" title="Code">💻</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://github.com/felipelovato"><img src="https://avatars.githubusercontent.com/u/2296173?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Felipe Lovato Flores</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=felipelovato" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/marcelkooi"><img src="https://avatars.githubusercontent.com/u/13142719?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Marcel Kooi</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=marcelkooi" title="Code">💻</a></td>
    <td align="center"><a href="http://leesharma.com/"><img src="https://avatars.githubusercontent.com/u/814638?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Lee Sharma</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=leesharma" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/scooter-dangle"><img src="https://avatars.githubusercontent.com/u/934707?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Scott Steele</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=scooter-dangle" title="Code">💻</a> <a href="#ideas-scooter-dangle" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://www.sam-we.com/"><img src="https://avatars.githubusercontent.com/u/10361390?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Sam Weerasinghe</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=oystersauce8" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/gerald"><img src="https://avatars.githubusercontent.com/u/46204?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Gerald Abrencillo</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=gerald" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/rodolfoasantos"><img src="https://avatars.githubusercontent.com/u/754389?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Rodolfo Santos</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=rodolfoasantos" title="Code">💻</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://www.linkedin.com/in/gabrielbaldao/"><img src="https://avatars.githubusercontent.com/u/20587352?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Gabriel Baldão</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=gabrielbaldao" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/melaniew"><img src="https://avatars.githubusercontent.com/u/1447452?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Melanie White</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=melaniew" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/holytoastr"><img src="https://avatars.githubusercontent.com/u/4822313?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Melissa Miller</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=holytoastr" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/marcheiligers"><img src="https://avatars.githubusercontent.com/u/173701?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Marc Heiligers</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=marcheiligers" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/josephbhunt"><img src="https://avatars.githubusercontent.com/u/78151?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Joe Hunt</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=josephbhunt" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/meg-gutshall"><img src="https://avatars.githubusercontent.com/u/37842352?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Meg Gutshall</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=meg-gutshall" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/ozydingo"><img src="https://avatars.githubusercontent.com/u/4616431?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Andrew H Schwartz</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=ozydingo" title="Code">💻</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://www.turing.io/alumni/joseph-glass"><img src="https://avatars.githubusercontent.com/u/17987273?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Joseph Glass</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=glassjoseph" title="Code">💻</a></td>
    <td align="center"><a href="https://reesew.io/"><img src="https://avatars.githubusercontent.com/u/26661872?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Reese Williams</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=reese" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/perezperret"><img src="https://avatars.githubusercontent.com/u/4761084?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Santiago Perez</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=perezperret" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/SiriusDely"><img src="https://avatars.githubusercontent.com/u/511437?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Sirius Dely</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=SiriusDely" title="Code">💻</a></td>
    <td align="center"><a href="http://heatherherrington.github.io/"><img src="https://avatars.githubusercontent.com/u/17165242?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Heather Herrington</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=heatherherrington" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/moacirguedes"><img src="https://avatars.githubusercontent.com/u/11277348?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Moacir Guedes</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=moacirguedes" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/CraigJZ"><img src="https://avatars.githubusercontent.com/u/7053190?v=4?s=100" width="100px;" alt=""/><br /><sub><b>CraigJZ</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=CraigJZ" title="Code">💻</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://www.linkedin.com/in/semiharslanoglu/"><img src="https://avatars.githubusercontent.com/u/10260283?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Semih Arslanoğlu</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=sarslanoglu" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/m-pereira"><img src="https://avatars.githubusercontent.com/u/47258878?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Mauricio de Lima</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=m-pereira" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/dacur"><img src="https://avatars.githubusercontent.com/u/4250366?v=4?s=100" width="100px;" alt=""/><br /><sub><b>David Curtis</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=dacur" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/nataliagalan"><img src="https://avatars.githubusercontent.com/u/66537500?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Natalia Galán</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=nataliagalan" title="Code">💻</a></td>
    <td align="center"><a href="http://andersonfernandes.dev/"><img src="https://avatars.githubusercontent.com/u/8173530?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Anderson Fernandes</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=andersonfernandes" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/belgamo"><img src="https://avatars.githubusercontent.com/u/19699724?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Gabriel Belgamo</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=belgamo" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/jorgedjr21"><img src="https://avatars.githubusercontent.com/u/4561599?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Jorge David C.T Junior</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=jorgedjr21" title="Code">💻</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://github.com/SethLieberman"><img src="https://avatars.githubusercontent.com/u/16119691?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Seth Lieberman</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=SethLieberman" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/jsantos"><img src="https://avatars.githubusercontent.com/u/32199?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Jorge Oliveira Santos</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=jsantos" title="Code">💻</a></td>
    <td align="center"><a href="http://www.dandrinkard.com/"><img src="https://avatars.githubusercontent.com/u/72645?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Drinks</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=drinks" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/brunohkbx"><img src="https://avatars.githubusercontent.com/u/6487206?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Bruno Castro</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=brunohkbx" title="Code">💻</a></td>
    <td align="center"><a href="http://xjunior.me/"><img src="https://avatars.githubusercontent.com/u/8156?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Carlos Palhares</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=xjunior" title="Code">💻</a></td>
    <td align="center"><a href="https://nepalmap.org/"><img src="https://avatars.githubusercontent.com/u/3824492?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Clifton McIntosh</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=cliftonmcintosh" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/Beigelman"><img src="https://avatars.githubusercontent.com/u/50420424?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Daniel Beigelman</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=Beigelman" title="Code">💻</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://github.com/lmegviar"><img src="https://avatars.githubusercontent.com/u/23217560?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Meg Viar</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=lmegviar" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/svileshina"><img src="https://avatars.githubusercontent.com/u/7723308?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Svetlana Vileshina</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=svileshina" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/bpr3p"><img src="https://avatars.githubusercontent.com/u/43351221?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Ben Reed</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=bpr3p" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/egiurleo"><img src="https://avatars.githubusercontent.com/u/9601737?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Emily Giurleo</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=egiurleo" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/alemtgetu"><img src="https://avatars.githubusercontent.com/u/36018687?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Alem Getu</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=alemtgetu" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/dejanbj"><img src="https://avatars.githubusercontent.com/u/7805837?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Dejan Bjeloglav</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=dejanbj" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/cassianoblonski"><img src="https://avatars.githubusercontent.com/u/9721558?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Cassiano Blonski Sampaio</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=cassianoblonski" title="Code">💻</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://github.com/gdombchik"><img src="https://avatars.githubusercontent.com/u/7111708?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Greg</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=gdombchik" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/finn2d"><img src="https://avatars.githubusercontent.com/u/84066080?v=4?s=100" width="100px;" alt=""/><br /><sub><b>finn</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=finn2d" title="Code">💻</a></td>
    <td align="center"><a href="https://jaysonmandani.github.io/"><img src="https://avatars.githubusercontent.com/u/1963153?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Jayson Mandani</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=JaysonMandani" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/stanleypliu"><img src="https://avatars.githubusercontent.com/u/53650048?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Stanley Liu</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=stanleypliu" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/c-bartell"><img src="https://avatars.githubusercontent.com/u/60277914?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Curtis Bartell</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=c-bartell" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/librod89"><img src="https://avatars.githubusercontent.com/u/4965672?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Libby Rodriguez</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=librod89" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/joshuacgraves"><img src="https://avatars.githubusercontent.com/u/53875700?v=4?s=100" width="100px;" alt=""/><br /><sub><b>joshuacgraves</b></sub></a><br /><a href="#question-joshuacgraves" title="Answering Questions">💬</a> <a href="#projectManagement-joshuacgraves" title="Project Management">📆</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://focused-wescoff-bfb488.netlify.app/"><img src="https://avatars.githubusercontent.com/u/65963997?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Himanshu</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=himanshu007-creator" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/MohamedHegab"><img src="https://avatars.githubusercontent.com/u/7612401?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Mohamed Hegab</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=MohamedHegab" title="Code">💻</a></td>
  </tr>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
