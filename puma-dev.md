
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

Link the application.
```
puma-dev link -n essentials {essentails_dir}
```

 For example, if your diaper repo clone is in `~/ruby/human-essentials`. You would run this:
```
puma-dev link -n essentials ~/ruby/human-essentials
```

Start `puma-dev`
```
puma-dev
```

You should now be able to access [essentials.test](http://essentials.test)!

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
