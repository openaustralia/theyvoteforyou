# Dev-only image, for running the app itself in Docker as an alternative to
# `bundle exec rails s` on the host (see `make dev-up` in the Makefile).
# Production doesn't use this - Capistrano builds Ruby from source on the
# server instead, see docs/adr/0003-rbenv-replaces-rvm.md.
ARG RUBY_VERSION=3.4.10
FROM docker.io/library/ruby:${RUBY_VERSION}-slim

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
      build-essential \
      default-libmysqlclient-dev \
      git \
      libyaml-dev \
      pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install

COPY . .

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
