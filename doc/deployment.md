# Deployment

## Infrastructure

The Human Essentials application is deployed to [fly.io](https://fly.io/) using the Dockerfile
instructions within the repo. At a high-level, we instruct a remote builder to build the application
using the Dockerfile and network settings are setup via the `fly.toml` configuration file.

## How Do You Deploy?

### Pre-reqs

- You must have an account with fly.io that has access to the Ruby For Good organization. (Ask in @edwinthinks or @seanmarcia for access)
- Installed [flyctl](https://fly.io/docs/getting-started/installing-flyctl/)

### Staging

*All changes made on the main branch are automatically deployed to staging via GitHub Action*

To deploy manually, run the following command to deploy to staging:
```
flyctl deploy --remote-only --build-arg RAILS_ENV=staging -a human-essentials-staging
```

### Production

Run the following command to deploy to production:
```
flyctl deploy --remote-only --build-arg RAILS_ENV=production -a human-essentials
```

## Encounter any issues?

Please let us know in the Ruby For Good slack channel #human-essentials.
