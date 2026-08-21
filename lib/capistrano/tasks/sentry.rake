# frozen_string_literal: true

namespace :sentry do
  desc "Notify Sentry of a new release and deploy"
  task :notify_deploy do
    run_locally do
      # Support both v4 ("sentry") and v3 ("sentry-cli") of the Sentry CLI.
      # See https://cli.sentry.dev/migrating-from-v3/
      cli =
        if test("which sentry")
          :sentry
        elsif test("which sentry-cli")
          :"sentry-cli"
        end

      unless cli
        warn "Sentry: sentry (or sentry-cli) not installed, skipping release tracking (see README)"
        next
      end

      revision = fetch(:current_revision)
      environment = fetch(:rails_env, fetch(:stage))
      # "openaustralia/theyvoteforyou" - the repository name as known to
      # Sentry's GitHub integration
      repo = fetch(:repo_url)[%r{github\.com[:/](.+?)(?:\.git)?\z}, 1]

      # v4 doesn't pick up the project from the repository's .sentryclirc the
      # way v3 does, so pass org and project explicitly (both versions accept
      # these flags).
      sentryclirc = File.read(File.expand_path("../../../.sentryclirc", __dir__))
      org = sentryclirc[/^org\s*=\s*(\S+)/, 1]
      project = sentryclirc[/^project\s*=\s*(\S+)/, 1]

      # v4 renamed the "releases" command group to "release".
      release_group = cli == :sentry ? :release : :releases
      release_cmd = lambda do |*args|
        execute cli, release_group, *args, "--org", org, "--project", project
      end

      created = begin
        release_cmd.call(:new, revision)
        true
      rescue StandardError => e
        warn "Sentry: creating release failed, continuing deploy: #{e.message}"
        false
      end

      if created
        begin
          # Associate the exact deployed commit server-side via Sentry's
          # GitHub integration - Sentry works out the commit range from the
          # previous release. (--auto would use the local checkout's HEAD,
          # which isn't necessarily the deployed revision.)
          release_cmd.call(:"set-commits", revision, "--commit", "#{repo}@#{revision}")
        rescue StandardError => e
          warn "Sentry: set-commits via GitHub integration failed, trying local git history: #{e.message}"
          begin
            release_cmd.call(:"set-commits", revision, "--local")
          rescue StandardError => e
            warn "Sentry: associating commits failed, continuing deploy: #{e.message}"
          end
        end

        begin
          release_cmd.call(:finalize, revision)
        rescue StandardError => e
          warn "Sentry: finalizing release failed, continuing deploy: #{e.message}"
        end

        begin
          if cli == :sentry
            # v4: "deploys new" is gone; environment is a positional argument.
            release_cmd.call(:deploy, revision, environment)
          else
            execute cli, :deploys, :new, "--release", revision, "-e", environment,
                    "--org", org, "--project", project
          end
        rescue StandardError => e
          warn "Sentry: recording deploy failed, continuing deploy: #{e.message}"
        end
      end
    end
  end

  after "deploy:publishing", "sentry:notify_deploy"
end
