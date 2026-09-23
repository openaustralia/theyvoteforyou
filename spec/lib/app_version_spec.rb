# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

describe AppVersion do
  describe ".short_sha" do
    # Capistrano writes the full 40 character SHA
    let(:deployed_sha) { "1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b" }

    def in_tmp_root
      Dir.mktmpdir do |dir|
        yield Pathname.new(dir)
      end
    end

    # A real repository with a real commit, so tests of the git fallback exercise it
    # rather than silently getting nil from a repository that has no HEAD.
    def commit_in(root)
      dir = root.to_s
      system("git", "init", "--quiet", dir, exception: true)
      # Local identity and no signing, so this works on a machine with no git config
      # and in CI, where there is no signing key
      system("git", "-C", dir, "config", "user.email", "test@example.com", exception: true)
      system("git", "-C", dir, "config", "user.name", "Test", exception: true)
      system("git", "-C", dir, "config", "commit.gpgsign", "false", exception: true)
      system("git", "-C", dir, "commit", "--allow-empty", "--quiet", "-m", "Test", exception: true)
      `git -C #{dir} rev-parse --short=7 HEAD`.strip
    end

    it "shortens the full SHA that Capistrano writes into REVISION" do
      in_tmp_root do |root|
        # Capistrano echoes the SHA, so the file ends with a newline
        File.write(root.join("REVISION"), "#{deployed_sha}\n")

        expect(described_class.short_sha(root:)).to eq "1a2b3c4"
      end
    end

    it "returns nil outside a git checkout when there is no REVISION file" do
      in_tmp_root do |root|
        expect(described_class.short_sha(root:)).to be_nil
      end
    end

    it "returns nil when the REVISION file is empty" do
      in_tmp_root do |root|
        File.write(root.join("REVISION"), "\n")

        expect(described_class.short_sha(root:)).to be_nil
      end
    end

    it "ignores a REVISION file that doesn't hold a SHA, rather than linking to nothing" do
      in_tmp_root do |root|
        File.write(root.join("REVISION"), "Not a SHA\n")

        expect(described_class.short_sha(root:)).to be_nil
      end
    end

    it "prefers the REVISION file over git, so a release reports what was deployed" do
      in_tmp_root do |root|
        git_sha = commit_in(root)
        File.write(root.join("REVISION"), "#{deployed_sha}\n")

        # Without this the test would pass on an implementation that checked git first,
        # because a repository with no commits returns nothing either way
        expect(git_sha).to match(/\A[0-9a-f]{7}\z/).and(satisfy { |sha| sha != deployed_sha[0, 7] })
        expect(described_class.short_sha(root:)).to eq "1a2b3c4"
      end
    end

    it "falls back to git when there is no REVISION file" do
      in_tmp_root do |root|
        git_sha = commit_in(root)

        expect(described_class.short_sha(root:)).to eq git_sha
      end
    end
  end
end
