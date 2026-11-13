# frozen_string_literal: true

# Records a release and deploy in Sentry after each successful deploy so
# issues can be tied to the deploy that introduced them.
#
# This is the canonical OAF release-tracking task, carried verbatim by each
# collection's repo. The convention lives in the infrastructure repo's
# docs/monitoring.md; change it there first, then update every copy.
#
# Runs locally on the deployer's machine (not the servers) because that's
# where the Sentry CLI and the full git history live. Org/project defaults
# come from the committed .sentryclirc; credentials come from each deployer's
# `sentry auth` login (CLI v4) or ~/.sentryclirc (v3).
namespace :sentry do
  desc "Record the release and deploy in Sentry"
  task :release do
    run_locally do
      # CLI v4 renamed the binary from sentry-cli to sentry, so support both,
      # preferring v4 (https://cli.sentry.dev/migrating-from-v3/). A candidate
      # only counts if it exists AND is authenticated.
      #
      # The two CLIs report authentication differently. v4 has `auth status`;
      # v3 has no such command and reports it through `info`. Don't reach for
      # `sentry info` on v4: it exits non-zero whenever no default org/project
      # is configured, even when the token is fine, which made every deploy
      # skip the release (openaustralia/planningalerts#2183).
      #
      # SSHKit's local backend execs commands directly rather than through a
      # shell, so a missing binary raises Errno::ENOENT instead of making
      # `test` return false. Treat it the same as an unauthenticated CLI.
      cli = %w[sentry sentry-cli].find do |candidate|
        test(candidate == "sentry" ? "sentry auth status" : "sentry-cli info")
      rescue Errno::ENOENT
        false
      end

      if cli.nil?
        warn <<~WARNING
          ********************************************************************
          WARNING: the Sentry CLI (sentry or sentry-cli) is not installed or
          not authenticated.

          This deploy was NOT recorded as a release in Sentry, so issues
          won't be linked to it. The deploy itself has still succeeded.

          To fix this for future deploys, see "Monitoring" in the
          infrastructure repo (docs/monitoring.md).
          ********************************************************************
        WARNING
        next
      end

      # Matches the release auto-detected by the Ruby SDK from the REVISION
      # file that Capistrano writes. The Sentry environment is always the
      # stage name (docs/monitoring.md).
      release = fetch(:current_revision)
      environment = fetch(:stage).to_s

      # v3 reads org and project from the committed .sentryclirc. v4 ignores
      # that file, so read the values here and pass them on the command line,
      # which keeps .sentryclirc the single source of truth for both.
      sentryclirc = File.read(File.expand_path("../../../.sentryclirc", __dir__))
      org = sentryclirc[/^\s*org\s*=\s*(\S+)/, 1]
      project = sentryclirc[/^\s*project\s*=\s*(\S+)/, 1]

      # The repository as Sentry's GitHub integration knows it, for
      # associating the exact deployed commit. Set :sentry_release_repo in
      # deploy.rb when the deployed code lives in a different repository to
      # the one being deployed from (Right to Know deploys
      # openaustralia/alaveteli).
      repo = fetch(:sentry_release_repo,
                   fetch(:repo_url).to_s[%r{github\.com[:/](.+?)(?:\.git)?\z}, 1])

      # v4 addresses a release as an "org/version" positional and scopes it
      # with --project; v3 reads both from .sentryclirc.
      versioned = "#{org}/#{release}"

      # Every step after the release exists is best-effort: the deploy itself
      # has already succeeded, so warn and continue rather than failing it on
      # a Sentry hiccup.
      created = begin
        if cli == "sentry"
          execute :sentry, "release", "create", "--project", project, versioned
        else
          execute :"sentry-cli", "releases", "new", release
        end
        true
      rescue StandardError => e
        warn "Sentry: creating release #{release} failed, continuing deploy: #{e.message}"
        false
      end

      if created
        begin
          # Associate the exact deployed commit server-side via Sentry's
          # GitHub integration - Sentry works out the commit range from the
          # previous release. (--auto would use the local checkout's HEAD,
          # which isn't necessarily the deployed revision.)
          if cli == "sentry"
            execute :sentry, "release", "set-commits", versioned, "--commit", "#{repo}@#{release}"
          else
            execute :"sentry-cli", "releases", "set-commits", release, "--commit", "#{repo}@#{release}"
          end
        rescue StandardError => e
          warn "Sentry: set-commits via the GitHub integration failed, trying local git history: #{e.message}"
          begin
            if cli == "sentry"
              execute :sentry, "release", "set-commits", versioned, "--local"
            else
              execute :"sentry-cli", "releases", "set-commits", release, "--local"
            end
          rescue StandardError => e
            warn "Sentry: associating commits failed, continuing deploy: #{e.message}"
          end
        end

        begin
          if cli == "sentry"
            execute :sentry, "release", "finalize", versioned
          else
            execute :"sentry-cli", "releases", "finalize", release
          end
        rescue StandardError => e
          warn "Sentry: finalizing release failed, continuing deploy: #{e.message}"
        end

        begin
          if cli == "sentry"
            # v4: "deploys new" is gone; the environment is a positional.
            execute :sentry, "release", "deploy", versioned, environment
          else
            execute :"sentry-cli", "deploys", "new", "--release", release, "-e", environment
          end
        rescue StandardError => e
          warn "Sentry: recording deploy failed, continuing deploy: #{e.message}"
        end
      end
    end
  end
end

after "deploy:finished", "sentry:release"
