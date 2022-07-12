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

```
git push heroku x.y.z:HEAD -f
```

### **Optional** Smoke Test


### Notify our users about the update


1. Cut the release

2. Write up the changes

3. Deploy to production

4. Quick smoke test. Attempt to login.

5. Send email out to bank users about the changes.

## What happens if we something goes wrong?

Rollback changes!
