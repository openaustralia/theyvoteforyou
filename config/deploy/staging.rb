# frozen_string_literal: true

set :branch, ENV.fetch("STAGING_BRANCH", "main")
set :deploy_to, "/srv/www/staging"

set :rails_env, "staging"

aws_ec2_register(user: "deploy")
