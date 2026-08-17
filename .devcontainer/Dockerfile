# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.4
FROM ghcr.io/rails/devcontainer/images/ruby:$RUBY_VERSION

# Useful Diagnostic/networking tools.
RUN sudo apt-get update -qq \
  && sudo apt-get install -y --no-install-recommends \
       iputils-ping \
       dnsutils \
       net-tools \
       curl \
       silversearcher-ag \
       chromium \
       chromium-driver \
  && sudo rm -rf /var/lib/apt/lists/*
