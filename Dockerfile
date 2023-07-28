FROM ruby:3.1.2
# Add an apt source for chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list
# Application deps
RUN apt-get update -qq \
  && apt-get install -y \
    build-essential \
    libpq-dev \
    postgresql-client \
    google-chrome-stable \
  && apt-get clean
# Set up the appuser user so we don't run as root
# Also so that file ownership isn't weird in Linux Dev mode
ARG uid=1000
ARG gid=1000
RUN echo groupadd -g $gid appuser
RUN groupadd -g $gid appuser
RUN useradd --create-home -u $uid -g $gid -ms /bin/bash appuser
USER appuser
WORKDIR /app
RUN gem install foreman bundler --conservative
COPY Gemfile Gemfile.lock /app/
RUN bundle install -j4 --full-index