## Production Infrastructure

* Single server hosted on Azure sponsored hosting with a staging server on Linode.
* Rails
* PostgresDB
* Puma
* Instance is used for all Diaper Banks (hosted service, not federated or self-hosted)

## Production Activity

* We're in production out of beta!
* These diaper banks are trying to use the system with real-world data
* That means the system is IN PRODUCTION and is the source-of-truth for some users
* There are no particular times of usage, though likely US-daylight
* Q: How do we communicate with users, like if we needed downtime?
  * Testing users are encouraged to submit GitHub issues (all of them? trained?)

## Deployment

* TravisCI deploys master
  * Triggered by merge into master -- now that we're in production, auto deploys go to our staging server (diaperbase.org.) Deploying to production requires tagging a release and then manually deploying it with Capistrano.
  * Runs Capistrano deploy if the rest of the tests pass
  * See [.travis.yml](https://github.com/rubyforgood/diaper/blob/main/.travis.yml)
* Capistrano is used to perform the deploy
  * See [config/deploy.rb](https://github.com/rubyforgood/diaper/blob/main/config/deploy.rb) for general config
  * See [config/deploy/production.rb](https://github.com/rubyforgood/diaper/blob/main/config/deploy/production.rb) for production config
  * Single server for DB and web server (Puma)
  * Uses hard-coded ip address
  * We have the ability to deploy from a branch `cap production deploy BRANCH=branch_to_deploy`

## Monitoring, Alerting, Metrics

* Bugsnag (we have an OSS account, contact an admin for access to it)
* [Skylight](https://oss.skylight.io/app/applications/LrXHcxDK7Be9/recent/6h/endpoints) - Monitoring service

## Production Debugging

* A few admins (a-a-ron, sean, jcavena) have production shell access
* We have the `capistrano-rails-console` gem installed. This allows us to run `cap production rails:console` which opens a production rails console from your local command line.

## Disaster Recovery

* [Issue #405 will add DB backups](https://github.com/rubyforgood/diaper/issues/405)
* VM Snapshot (?)
