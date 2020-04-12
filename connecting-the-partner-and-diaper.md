# Intro

![Image Of Diaper & Partner App Connected Through API](/partner-and-diaper-connection-illustration.png)

In production, the `partner` and `diaper` application depend on each other. There are crucial  flows that require this connection to exist. For example, the flow for registering and approving a new "partner user" requires a back-and-forth communication between the two applications. If you wanted to change aspects of this flow, you'd may need to change code in both applications.

In those cases, you'd  benefit greatly from establishing this communication locally and should follow this guide to get your local environment setup.


# Pre-requirements

Ensure that you are able to run both `partner` and `diaper` repos individually by following the README in their respective repos. This guide doesn't cover setting up the database or configure applications for basic user.

Please verify the following before continuing

- [ ]  You are using Linux or MacOSX
- [ ]  You went through the setup instructions in the `partner` and `diaper` README
- [ ]  You are able to run and access `partner` and `diaper` individually.

# Configure Applications

You must setup the ENV variables properly on both applications before proceeding to the following sections of this guide. 

In your `diaper` application ensure that you have a `.env` folder with these contents:
```
PARTNER_KEY="secretpassword"
PARTNER_REGISTER_URL="https://partner.test/api/v1/partners"
PARTNER_ADD_URL="https://partner.test/api/v1/add_partners"
PARTNER_APPROVAL_URL="https://partner.test/api/v1/approve"
PARTNER_FORM_URL="https://partner.test/api/v1/partner_forms"
PARTNER_BASE_URL="partner.test"
FLIPPER_USERNAME="admin"
FLIPPER_PASSWORD="password"
SIDEKIQ_USERNAME="admin"
SIDEKIQ_PASSWORD="password"
DIAPERBANK_KEY="secretpassword"
DIAPERBANK_ENDPOINT="https://diaper.test/api/v1"
```
In your `partner` application ensure that you have a `.env` folder with these contents:
```
DIAPERBANK_KEY="secretpassword"
DIAPERBANK_ENDPOINT="https://diaper.test/api/v1"
DIAPERBANK_APPROVAL_URL="https://diaper.test/api/v1/partner_approvals"
DIAPERBANK_PARTNER_REQUEST_URL="https://diaper.test/api/v1/partner_requests"
FLIPPER_USERNAME="admin"
FLIPPER_PASSWORD="password"
```
# Setup Puma Dev

### MacOSX Installation & Setup

Download and install `puma-dev` through homebrew
```
brew install puma/puma/puma-dev
```
Setup & Install `puma-dev`
```
sudo puma-dev -setup 
puma-dev -install 
```

Link the applications. Replace the `{diaper_dir}` and `{partner_dir}` with the **absolute directory path of the repos you've cloned.**
```
puma-dev link -n diaper {diaper_dir}
puma-dev link -n partner {partner_dir}
```

 For example, if your diaper repo clone is in `~/ruby/diaper` directory and `partner` is in `~/ruby/partner`. You would run these:
```
puma-dev link -n diaper ~/ruby/diaper 
puma-dev link -n partner ~/ruby/partner
```

Start `puma-dev`
```
puma-dev
```

You should now be able to access diaper.test and [partner.test](http://partner.test/)!

### Linux Installation & Setup

Please refer to the [linux guide]([https://github.com/puma/puma-dev#linux-support](https://github.com/puma/puma-dev#linux-support)) from the puma-dev repo or instructions.

# Viewing Application Logs

If you are running MacOSX, you can view the logs of `puma-dev` (not application) located at `~/Library/Logs/puma-dev.log`.  **Does not include in-depth information of your application requests or processes.**

The application logs which contains a-lot more details about how your application's activities can be found in the `/log/development.log` file within your application's repo. 

To simplify development, you can choose to tail and follow the logs. This way you do not have to re-open the log file every-time you want to see changes.
```bash
tail -F /log/development.log
```

### Running background jobs

Communication between the partner and diaper app mostly occur in jobs that run in the background via sidekiq. To enable this you need to start sidekiq in the diaper repo and have it handle the default queue.
```bash
bundle exec sidekiq -q default
```
# Troubleshooting

#####  My ENV variables are incorrect even though I changed them in the `.env` file

Try running `puma-dev -uninstall` and then running `puma-dev -install` again. It appears that the ENV variables (maybe initialization) doesn't change unless you re-install puma-dev.

##### Creating a partner on the diaper app does not seem to trigger a invite on the partner application.
As of today, you need to explicitly tell `Flipper` to enable sending emails locally. You can do this by opening up the rails console in diaper and running `Flipper.activate(:email_active).` You will need to re-queue the invitation request again.

