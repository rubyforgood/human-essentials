FROM ruby:2.5.3

WORKDIR /code
COPY Gemfile* /code/
RUN bundle

COPY . /code/

CMD ["puma"]
EXPOSE 3000