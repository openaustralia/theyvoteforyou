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

  # Anything that isn't a SHA is treated as no answer at all, so a truncated or corrupt
  # REVISION leaves the sentence out instead of linking to a commit that doesn't exist.
  # git lengthens its short SHA past SHORT_LENGTH when 7 characters would be ambiguous,
  # so allow up to a full 40.
  SHA_FORMAT = /\A[0-9a-f]{7,40}\z/

  # Memoised per root because the answer cannot change while the process lives: a deploy
  # builds a new release directory and restarts. Without this, every /about request on a
  # deployment with no REVISION file, and every one in development, would fork a git
  # subprocess. One consequence worth knowing when checking this by hand: creating a
  # REVISION file part way through a process's life won't be picked up.
  #
  # root: exists only so specs can point at a real temporary directory instead of
  # stubbing File.
  def self.short_sha(root: Rails.root)
    @short_sha ||= {}
    key = root.to_s
    return @short_sha[key] if @short_sha.key?(key)

    @short_sha[key] = from_revision_file(root) || from_git(root)
  end

  def self.from_revision_file(root)
    path = root.join("REVISION")
    return unless File.exist?(path)

    sha = File.read(path).strip
    sha[0, SHORT_LENGTH] if sha.match?(SHA_FORMAT)
  end
  private_class_method :from_revision_file

  # Redirecting stderr means this runs via /bin/sh, so a missing git or a directory
  # outside any repository gives us empty output rather than raising Errno::ENOENT.
  # git -C avoids Dir.chdir, which isn't thread safe. The result is not truncated: git
  # has already given us the shortest unambiguous form.
  def self.from_git(root)
    sha = `git -C #{Shellwords.escape(root.to_s)} rev-parse --short=#{SHORT_LENGTH} HEAD 2>/dev/null`.strip
    sha if sha.match?(SHA_FORMAT)
  end
  private_class_method :from_git
end
