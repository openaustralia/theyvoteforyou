# frozen_string_literal: true

namespace :sentry do
  desc "Notify Sentry of a new release and deploy"
  task :notify_deploy do
    run_locally do
      unless test("which sentry-cli")
        warn "Sentry: sentry-cli not installed, skipping release tracking (see README)"
        next
      end

      revision = fetch(:current_revision)
      environment = fetch(:rails_env, fetch(:stage))

      begin
        execute :"sentry-cli", :releases, :new, revision
        execute :"sentry-cli", :releases, :"set-commits", revision, "--local"
        execute :"sentry-cli", :releases, :finalize, revision
        execute :"sentry-cli", :deploys, :new, "--release", revision, "-e", environment
      rescue StandardError => e
        warn "Sentry: release tracking failed, continuing deploy: #{e.message}"
      end
    end
  end

  after "deploy:publishing", "sentry:notify_deploy"
end
