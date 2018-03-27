FROM ruby:2.4.2

RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && \
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update
RUN apt-get install -y postgresql-client-9.5

# Install phantomjs for rspec
ARG PHANTOM_VERSION=2.1.1
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y curl fontconfig cmake \
    && cd /tmp \
    && curl -L -O https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-${PHANTOM_VERSION}-linux-x86_64.tar.bz2 \
    && tar xvjf phantomjs-${PHANTOM_VERSION}-linux-x86_64.tar.bz2 \
    && cp /tmp/phantomjs-*/bin/phantomjs /usr/local/bin/phantomjs

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --binstubs

COPY . .

CMD puma -C config/puma.rb
