# Installs Ruby 3.4. When human-essentials moves to a newer version of ruby,
# it will be more efficient to change the image.
# See https://github.com/devcontainers/images/blob/main/src/ruby/history/
#
# See devcontainers/features#1431 for why we include the `-bookworm`
# suffix. Once that issue is resolved, we can remove the suffix, which
# will let us follow the debian upgrade to trixie.
FROM mcr.microsoft.com/devcontainers/ruby:dev-3.4-bookworm
RUN export DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y install vim curl gpg postgresql postgresql-contrib
RUN cd /tmp
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get -y install ./google-chrome-stable_current_amd64.deb
