# Dev-only image, for running the app itself in Docker as an alternative to
# `bundle exec rails s` on the host (see `make up` in the Makefile).
# Production doesn't use this - Capistrano builds Ruby from source on the
# server instead, see docs/adr/0003-rbenv-replaces-rvm.md.
#
# It matches the current production server: Ubuntu 20.04 (focal) with Ruby built from source, at the version in the
# infrastructure repo's group_vars/theyvoteforyou.yml. buildpack-deps is the base the official Ruby images use, so it
# brings the same development libraries for building gems.
#
# When the theyvoteforyou2026 server (Ubuntu 26.04 on ARM, host_vars/theyvoteforyou2026.yml) takes over production:
# - change FROM to the buildpack-deps tag for Ubuntu 26.04
# - set RUBY_VERSION to that server's ruby_versions, if it differs
# - nothing else is architecture specific: Docker builds for the machine it runs on, so Apple Silicon will then run
#   natively, like production
FROM buildpack-deps:focal

ARG RUBY_VERSION=3.4.10
RUN git clone --depth 1 https://github.com/rbenv/ruby-build.git /tmp/ruby-build \
    && /tmp/ruby-build/bin/ruby-build "$RUBY_VERSION" /usr/local \
    && rm -rf /tmp/ruby-build

# UTF-8 like production, and gems in /usr/local/bundle (compose.yaml's bundle_cache volume), as the official Ruby
# images set them
ENV LANG=C.UTF-8 GEM_HOME=/usr/local/bundle BUNDLE_APP_CONFIG=/usr/local/bundle BUNDLE_SILENCE_ROOT_WARNING=1
ENV PATH=/usr/local/bundle/bin:$PATH

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
      default-libmysqlclient-dev \
      libyaml-dev \
      tidy \
    && rm -rf /var/lib/apt/lists/*

# Google Chrome for the :js feature specs, as CI has (Ubuntu's chromium package is a snap, which can't run here).
# Google publishes no Linux ARM build, so on ARM those specs are skipped instead (see spec/support/capybara.rb).
ARG TARGETARCH
RUN if [ "$TARGETARCH" = amd64 ]; then \
      curl -fsSL -o /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
      && apt-get update -qq && apt-get install -y --no-install-recommends /tmp/chrome.deb \
      && rm -rf /tmp/chrome.deb /var/lib/apt/lists/*; \
    fi

# Run as a non-root "deploy" user, so files the app writes into the bind-mounted checkout (config/database.yml, log,
# tmp) belong to you rather than root. On Linux, set UID and GID in .env if your own ids (`id -u`, `id -g`) aren't
# 1000. Leave them unset on macOS: Docker Desktop maps file ownership on bind mounts itself, and macOS's gid 20 clashes
# with an existing group in the image.
ARG UID=1000
ARG GID=1000
RUN groupadd --gid "$GID" deploy \
    && useradd --uid "$UID" --gid deploy -m deploy \
    && mkdir -p /usr/local/bundle /app \
    && chown deploy:deploy /usr/local/bundle /app
USER deploy

WORKDIR /app

COPY --chown=deploy:deploy Gemfile Gemfile.lock .ruby-version ./
RUN bundle install

COPY --chown=deploy:deploy . .

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
