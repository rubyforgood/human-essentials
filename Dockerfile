FROM ruby:2.7.1-slim-buster
ENTRYPOINT [ "/bin/bash", "docker-entrypoint.sh" ]
CMD [ "diaper" ]
WORKDIR /opt/diaper

ARG DIAPER_PORT=3000

ENV DIAPER_PORT=${DIAPER_PORT}

EXPOSE ${DIAPER_PORT}

RUN apt update &&\
    apt install -y \
    build-essential \
    curl \
    imagemagick \
    libpq-dev \
    nodejs \
    postgresql \
    ruby-dev \
    yarn &&\
  rm -rf /var/lib/apt/lists/* &&\
  bundle config --global frozen 1

COPY Gemfile Gemfile.lock /opt/diaper/

RUN bundle install

COPY . /opt/diaper/
