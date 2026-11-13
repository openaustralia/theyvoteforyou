# frozen_string_literal: true

set :branch, :main
set :deploy_to, "/srv/www/production"

set :rails_env, "production"

aws_ec2_register(user: "deploy")
