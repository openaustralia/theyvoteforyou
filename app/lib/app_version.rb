# frozen_string_literal: true

require "shellwords"

# The git revision of the code that's currently running, for display on the About page.
#
# Capistrano writes a REVISION file containing the full SHA into every release directory;
# Sentry reads that same file to tag releases (see config/initializers/sentry.rb). A
# development checkout has no REVISION file, so we ask git instead. Anything else - notably
# the Mina-deployed Ukraine site, which writes no REVISION - gets nil, and the About page
# leaves the version sentence out rather than showing a broken commit link.
module AppVersion
  # GitHub resolves a 7 character prefix, which is short enough to read out loud.
  SHORT_LENGTH = 7

  # root: exists only so specs can point at a real temporary directory instead of
  # stubbing File.
  def self.short_sha(root: Rails.root)
    from_revision_file(root) || from_git(root)
  end

  def self.from_revision_file(root)
    path = root.join("REVISION")
    return unless File.exist?(path)

    File.read(path).strip[0, SHORT_LENGTH].presence
  end
  private_class_method :from_revision_file

  # Redirecting stderr means this runs via /bin/sh, so a missing git or a directory
  # outside any repository gives us empty output rather than raising Errno::ENOENT.
  # git -C avoids Dir.chdir, which isn't thread safe.
  def self.from_git(root)
    `git -C #{Shellwords.escape(root.to_s)} rev-parse --short=#{SHORT_LENGTH} HEAD 2>/dev/null`.strip.presence
  end
  private_class_method :from_git
end
