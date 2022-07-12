# Releases & Deployments

This document contains the information you'll need to understand when, what, who and how to release newer versions of the Human Essentials into production so that our wonderful users can get the latest features and bug fixes.

# Release Overview

### What do we release?
All code that has been merged into the `main` branch will be released.

### Cadence
Releases occur every 1st and 3rd weekend of every month so that it aligns nicely with our monthly stakeholder meeting.

### Managers
A select group of maintainers of the Human Essentials project are responsible for releasing updates. Here are the current release managers:
- @edwinthinks
- @cielf
- @scooter-dangle
- @dorner

# Release Process

## Pre-requistes
- Deployment access to the human-essentials project on heroku.
- Able to execute `rails fetch_latest_db` to get production data locally
- Be included in the list of release managers in this document

## Step-By-Step Guide


### Tag & Create Release
1. Create & push a new tag with a incremented version number using semantic versioning.

2. Create a release on the repo using this template:
```
## ✨ What's New?
- Update 1

## 🐞 Bug Fixes
- Bug Fix 1

## 💖 Other Changes
- Change 1
```

Use your best judgement of what to include or not to include. Ideally, aim to be clear but without getting too heavily into technical details.

### Deploy To Production

Now that you've cut the release, it is time to deploy it to production which is currently being hosted on Heroku.

1. If you haven't set up the heroku remote yet, you must first add it:
```
git remote add heroku <HEROKU_GIT_URL>
```

2. Push the release tag to production
```
git push heroku x.y.z:main -f
```

### Notify our users about the update
Once deployment is completed, you are now ready to notify our users on what has changed.

1. Fetch the list of emails of banks by pulling down production via `rails fetch_latest_db` and run
```
emails = User.all.pluck(:email)
puts "Email Address\n" + emails.join("\n") 
```

2. Send a short email and include details from the release notes.

## What happens if we something goes wrong?

If you notice that something didn't work out, you are able to rollback. Navigate to the "Activity" tab of the project in heroku and click "Roll back to here" on the last deployment. If that doesn't work -- you should notify the rest of the release managers to get some assistance.
