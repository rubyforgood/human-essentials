# Installing on Ubuntu

Following are instructions for installing DiaperBase on a freshly installed Ubuntu Desktop host. This will probably work identically on Ubuntu Server but that has not been tested yet.

Many of these instructions can probably work as is, or easily be translated to work on a Mac.

There are two kinds of installations; one for a developer and another for a deployment. The only difference between the two is that the former will need git installed and need to `git clone` the repo, whereas the latter can just download a copy of master.

Obviously, if any of these steps are already done you will probably not need to do them, so just ignore those steps.


### Project Page

The Github project page is at [https://github.com/rubyforgood/diaper](https://github.com/rubyforgood/diaper).


### Installing OS Packages

You'll need to add some packages to those that are included in the installation by default:

#### Ubuntu

`sudo apt install curl  git  nodejs  npm  postgresql  libpq-dev`

#### OS X

Install [Homebrew](https://brew.sh/) if you don't already have it

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Then install these packages

```
brew install node
brew install postgresql
```


### Installing the Diaper Software

If you will be using this machine for development, you will need to `git clone` the repo:

`git clone https://github.com/rubyforgood/diaper.git`

If you only need to have the files but don't need to use git, you can download the zip file and unzip it:

```
curl -o diaper.zip https://codeload.github.com/rubyforgood/diaper/zip/master \
    && unzip diaper.zip \
    && rm diaper.zip
```


### Installing Yarn

Go to your diaper project directory and do this:

#### Ubuntu

```
sudo npm -g install yarn
yarn install
```

### OS X

```
brew install yarn
yarn install
brew install imagemagick
```


### Installing rvm

Go to https://rvm.io/rvm/install and find and run the commands that install the gpg key and install rvm. At the time of this writing (2019-07-26), they are:

```
gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
\curl -sSL https://get.rvm.io | bash
```

_Open a new terminal tab or window (this will not work in your current shell!)._ To test rvm, do:

`rvm list`

If you see something like ‘rvm not found’, you may need to change your terminal settings so that something like “Run command as a login shell” is selected. In the default Ubuntu terminal, you would go to the Edit menu, then select the profile to edit, then select the “Command” tab, and select “Run command as a login shell”. Then open a new shell to proceed.


### Installing Ruby and Ruby Gems

Install the required version of Ruby (you may be prompted for your system password so that rvm can install some required packages):

`rvm install $(cat .ruby-version)`

Then, from your project directory, install the gems required for the project:

`bundle`


### Configuring Postgres

Copy the database.yml file:

    $ cp config/database.yml.example config/database.yml

By default, Postgres has no password for the admin user. You'll need to set one. Run `psql` as the Unix user `postgres` that was added by the Postgres installation (Ubuntu only):

#### Ubuntu

`sudo -u postgres psql`

#### OS X

```
brew services start postgresql
psql postgres
```

In `psql`, the following command would add a password whose value is `password`. For the default OS X / HomeBrew setup, the postgres user is not created but you view the user list using `\du` in psql. Replace `postgres`, below, with the user name.

`alter user postgres password 'password';`

Don't forget that semicolon!

You can now exit `psql`, by pressing `<Ctrl-D>` or typing `\q<Enter>`.


### Making the Postgres Credentials Available in Your Environment

You will see in `config/database.yml` that the Postgres username and password are fetched from the environment variables `PG_USERNAME` and `PG_PASSWORD`, respectively. (The production environment password is an exception, coming from `DIAPER_DATABASE_PASSWORD`.) You'll need to make this happen, for example by putting them in a startup script, or (quick and dirty) typing `export` commands in the terminal:

For OS X users, remember to replace `postgres`, below, with the user name you used in psql.

```
export PG_USERNAME=postgres
export PG_PASSWORD=password
```

### Initializing the Data Base

From your project directory, initialize the data base:

`rails db:setup`


### Testing the Application

You should now be able to successfully run the application:

`rails server`

Point a browser to `localhost:3000`. You should see the Diaper home page. For login credentials, consult the README.md file (at the time of this writing at [https://github.com/rubyforgood/diaper/blob/master/README.md#login](https://github.com/rubyforgood/diaper/blob/master/README.md#login).


# Using Docker with Mutagen

There has been some attriction in the past with Docker on MacOS because of poor sync performance of named volumes. Mutagen is a new way to perform sync between data in the container and residing on the host that is both cross-platform and promises much better performance on MacOS.

## Set up

You need at least `docker >= 19.03`, `docker-compose >= 1.22.0` and `mutagen >= 0.12.0-beta2`. At the time of this writing, the needed feature is still in beta, but was functional on our tests. [Check here](https://github.com/mutagen-io/mutagen/releases) if there is a stable version that is greater than the version stated before if you want to be extra safe.

### MacOS

Run:

```
brew update
brew cask install docker
brew install docker-compose
```

If still only beta versions of mutagen 0.12 series are available, use the following command to install mutagen:

```
brew install mutagen-io/mutagen/mutagen-beta
```

Otherwise:

```
brew install mutagen-io/mutagen/mutagen
```

### GNU/Linux

Follow the setup of docker and docker-compose for your distro, then install mutagen from the `All distros` section.

#### Fedora >= 31

Run:

```
sudo dnf install moby-engine docker-compose
sudo systemctl enable --now docker
```

#### Ubuntu >= 20.04

Run:

```
sudo apt update
sudo apt install docker.io docker-compose
```

#### All distros

Download a version of `mutagen >= 0.12.0-beta2` that is for Linux and probably in your case for the amd64 architecture from the [official Mutagen repo](https://github.com/mutagen-io/mutagen/releases) and install it to `/usr/local/bin`:

```
curl https://github.com/mutagen-io/mutagen/releases/download/v0.12.0-beta2/mutagen_linux_amd64_v0.12.0-beta2.tar.gz -o mutagen.tar.gz
tar -zxvf mutagen.tar.gz
sudo cp -R mutagen mutagen-agents.tar.gz /usr/local/bin
```

### Windows

TO DO

## Running diaper

Change directory to the root of Diaper's source code and then run:

```
mutagen compose up --build
```

Finally, just point your browser to <http://127.0.0.1:3000>.
