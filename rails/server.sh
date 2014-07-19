#!/bin/sh

# Runs the rails server and delayed job processing.
# The advantage to doing this in a script is that the jobs:work stuff will
# automatically be stopped when the web server is.
# This should only be used for running a test server during development of
# course.

set -e

JOB_LOG="$(mktemp --tmpdir publicwhip_jobs.XXXXXX)"
bundle exec rake jobs:work > $JOB_LOG 2>&1 &
echo "Processing delayed jobs in the background, log file at $JOB_LOG"
bundle exec rails server
