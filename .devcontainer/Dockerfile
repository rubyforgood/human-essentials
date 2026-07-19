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
# Headless browser for Cuprite/Capybara system specs. Google Chrome only ships
# an amd64 .deb, so on arm64 (Apple Silicon hosts) install Debian's Chromium
# instead, which Ferrum/Cuprite auto-detects. On amd64 keep upstream Chrome.
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    if [ "$arch" = "amd64" ]; then \
      cd /tmp && wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
        && apt-get -y install ./google-chrome-stable_current_amd64.deb; \
    else \
      apt-get -y install chromium; \
    fi
