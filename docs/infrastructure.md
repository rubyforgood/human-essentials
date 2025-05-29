# Infrastructure

Human Essentials is hosted on AWS and administered using Cloud66.

The infrastructure consists of:

* Two Cloud66 "applications" - one for staging and one for production.
* Both applications have a single instance, corresponding to an AWS EC2 server.
* Production has a load balancer, while staging does not. The primary reason is for easier Ruby upgrades.
* There is an RDS Postgres database instance which both production and staging share (with different logical Postgres databases within it). The database has automatic backups turned on. This is considered external to Cloud66 - i.e. it is not configured within Cloud66 but via environment variables.
* There are a total of three S3 buckets:
  * `human-essential-production` - this stores ActiveStorage attachments for prod.
  * `human-essential-staging` - ditto for staging.
  * `human-essential-backups` - this stores database backups that are used in the database restore process, below.
* Human Essentials does not use Redis for any purpose.

There is an additional instance on [fly.io](https://fly.io) which hosts a [Metabase](https://human-essentials-metabase.fly.dev/) application. This is used for ad-hoc querying by members of the core team.

## Processes

There are two primary processes aside from the main Rails server (these are set up as "Workers" in Cloud66):

* Delayed Jobs (`rake jobs:work`): These process ActiveJobs that are queued up - these are primarily e-mails that have to be sent out asynchronously.
* Clock (`clock`): This is a gem that acts as a cron manager to run particular actions. You can see these in `clock.rb`.

## Staging data

Staging data is based on the seed data in `seeds.rb`. There is a `clock` process to reset staging data to the seeds every day. So it's safe to make any changes on staging - just realize that they'll be blown away by the next day.

## Backup and restore

We have a method in place to backup and restore the entire production database. It works as follows:

* Every 4 hours, the `BackupDbRds` process is run. This runs `pg_dump` on the production database and uploads it to S3.
* To restore this to your local database, you need to have an AWS account which has been given access to the `human-essentials-backups` S3 bucket. Once this is in place, and your [credentials are set](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html), you can run `rake fetch_latest_db`, which will download the S3 file, blow away your local DB and replace it with production. Obviously only core team devs will be given this access. 

Note that this can't use RDS database backups as there is no easy way to restore one of those to your local database.

## Integrations

We have accounts with the following services:

* [SmartBear Insight Hub](https://app.bugsnag.com/ruby-for-good/human-essentials/overview?release_stage=production) (previously Bugsnag) - provides error traces in a handy inbox.
* [Newrelic](https://one.newrelic.com/) - provides APM traces and log aggregation. We have a free account, so only one user can see this information at a time.
* [Knapsack Pro](https://knapsackpro.com/) - this allows us to easily split up our tests on CI in a way that evenly divides the runtime.

## CI

We have a number of CI processes that run:

* Every PR has to pass lint and RSpec tests.
* We have an auto-comment CI that runs after each release and comments on the PRs that went into it.
* We have Dependabot set up to auto-create dependency upgrade PRs.
* Issues are automatically marked as stale after 30 days and unassigned 7 days after that.

## Deploys

Deploys are handled by Cloud66. The process is as follows:

* A Git tag is created and pushed onto the `main` branch.
* A new release is created.
* The current deploy target for Cloud66 is changed to the new tag.
* The deploy is then triggered.

Staging deploys are set to the `main` branch - so every time the `main` branch has a new commit, it is auto-deployed to staging.

