# frozen_string_literal: true

require "etc"

set :branch, ENV.fetch("STAGING_BRANCH", "main")
set :deploy_to, "/srv/www/staging"

set :rails_env, "staging"

# Anything but "1" counts as not set, so a stray DEPLOY_LOCAL=false in someone's shell cannot send a deploy to
# their own machine.
if ENV["DEPLOY_LOCAL"] == "1"
  # Set when this deploy runs on the server itself, started by the deploy service (see oaf-deploy-bottle, in its
  # own repository on GitLab), rather than from a developer's machine through AWS SSM. SSHKit's local backend
  # runs the commands directly as the current user, so no SSH login to localhost, and no key for one, is needed.
  # See https://github.com/capistrano/sshkit (Backend::Local).
  deploy_user = Etc.getpwuid(Process.uid).name
  raise "DEPLOY_LOCAL=1 is for the staging server and must run as deploy, not #{deploy_user}." unless deploy_user == "deploy"

  set :sshkit_backend, SSHKit::Backend::Local
  server "localhost", roles: %w[app web db]

  # tagging3 pushes a git tag to origin after every deploy. The server only has read access to the (public)
  # repo and should not be given write credentials just for this, so skip it. The deployed revision is still
  # recorded in the release's REVISION file.
  %w[tagging3:deploy tagging3:cleanup].each do |name|
    Rake::Task[name].clear_actions if Rake::Task.task_defined?(name)
  end
else
  aws_ec2_register(user: "deploy")
end
