**Nix**

If you have [Nix](https://nixos.org) installed you can use the [flake.nix](flake.nix) configuration file located at the root of the project to build and develop within an environment without needing to install `rvm`, `postgresql` or other tools separately.
The environment also uses the `gemset.nix` file to automatically download and install all the gems necessary to get the server up and running. This means you will not need run `bundle exec` or any `bundle` commands.

INSTRUCTIONS:

1. Install [Nix](https://zero-to-nix.com/concepts/nix-installer)
2. Add the following to `~/.config/nix/nix.conf` or `/etc/nix/nix.conf`:

```
    experimental-features = nix-command flakes
```

3. `cd` into human-essentials
4. Copy `.env.example` to `.env` and set correct values
5. `nix develop` and wait for the packages to be downloaded and the environment to be built
6. If the Gemfile changes run `update-deps` to update `gemset.nix`

The database will be created when running `nix develop` for the first time. If you did not set up your `.env` and database creating failed you can run `setup-db` or use `rails db:` commands.

This will run on Linux and macOS.
