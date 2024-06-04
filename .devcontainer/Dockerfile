# Installs Ruby 3.2.2. When human-essentials moves to a newer version of ruby,
# it will be more efficient to change the image.
# See https://github.com/devcontainers/images/blob/main/src/ruby/history/
FROM mcr.microsoft.com/devcontainers/ruby:dev-3.2-buster
RUN apt -y update && apt install -y vim curl gpg postgresql postgresql-contrib
RUN cd /tmp
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb 
RUN apt install -y ./google-chrome-stable_current_amd64.deb 