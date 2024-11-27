# Installs Ruby 3.2.2. When human-essentials moves to a newer version of ruby,
# it will be more efficient to change the image.
# See https://github.com/devcontainers/images/blob/main/src/ruby/history/
FROM mcr.microsoft.com/devcontainers/ruby:dev-3.2-buster
RUN export DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y install vim curl gpg postgresql postgresql-contrib
RUN cd /tmp
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get -y install ./google-chrome-stable_current_amd64.deb