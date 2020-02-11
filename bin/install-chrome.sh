#!/bin/bash

set -xeo pipefail


curl -sS -L https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list

apt-get update -q
env DEBIAN_FRONTEND="noninteractive" apt-get install -y unzip google-chrome-stable
rm -rf /var/lib/apt/lists/*


# Install ChromeDriver
wget -q https://chromedriver.storage.googleapis.com/2.40/chromedriver_linux64.zip
unzip chromedriver_linux64.zip -d /usr/local/bin
rm -f chromedriver_linux64.zip
