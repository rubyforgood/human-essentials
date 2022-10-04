# Contributing  
We ♥ contributors! By participating in this project, you agree to abide by the Ruby for Good [code of conduct](https://github.com/rubyforgood/human-essentials/blob/main/code-of-conduct.md).

If you have any questions about an issue, comment on the issue, open a new issue or ask in [the RubyForGood slack](https://rubyforgood.herokuapp.com/). human-essentials has a `#human-essentials` channel in the Slack. Our channel in slack also contains a zoom link for office hours every day office hours are held.  
  
You won't be yelled at for giving your best effort. The worst that can happen is that you'll be politely asked to change something. We appreciate any sort of contributions, and don't want a wall of rules to get in the way of that.

## Contributing Steps  
### Issues  
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
   - `rubocop -a`

1. Push to your branch/fork and submit a pull request. Include the issue number (ex. `Resolves #1`) in the PR description. This will ensure the issue gets closed automatically when the pull request gets merged.

## 🤝 Contributing Guidelines

Please feel free to contribute! While we welcome all contributions to this app, pull-requests that address outstanding Issues *and* have appropriate test coverage for them will be strongly prioritized. In particular, addressing issues that are tagged with the next milestone should be prioritized higher.

To contribute, do these things:

 * **Identify an issue** you want to work on that is not currently assigned to anyone
 * **Assign it** or have it assigned to yourself (so that no one else works on it while you are)
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
