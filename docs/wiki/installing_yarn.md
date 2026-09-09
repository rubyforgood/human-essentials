Since we now use `webpacker`, we also use `yarn` to maintain our JS assets. 

# Platforms
Installing `yarn` is different depending on your OS. Find your platform below and follow the directions.

## Linux
 1. Add the repository
```bash
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
```
 2. Install `yarn`
```bash
sudo apt-get update && sudo apt-get install yarn
```
If you run into trouble, check the [source page](https://yarnpkg.com/lang/en/docs/install/#debian-stable). 

## Mac
Easiest to install this via [Homebrew](https://brew.sh/)
```bash
brew install yarn
```
If you run into trouble, check the [source page](https://yarnpkg.com/lang/en/docs/install/#mac-stable)

## Cloud 9

You can't just follow the [directions on the site](https://yarnpkg.com/lang/en/docs/install/#linux-tab), you have to do some mojo first.

 1. Run update.
```bash
sudo apt-get update
```

 2. Install apt-transport-https.
```bash
sudo apt-get install apt-transport-https
```

 3. Configure the repository (from Yarn installation).
```bash
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
```

 4. Run update again and install Yarn.
```bash
sudo apt-get update && sudo apt-get install yarn
```

You're good to go! (Thanks to [Mike Rourke](https://gist.github.com/mikerourke/0c2cac1bec77fb4c1d875bfaee487074))