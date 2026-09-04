# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

describe AppVersion do
  describe ".short_sha" do
    def in_tmp_root
      Dir.mktmpdir do |dir|
        yield Pathname.new(dir)
      end
    end

    it "shortens the full SHA that Capistrano writes into REVISION" do
      in_tmp_root do |root|
        # Capistrano echoes the SHA, so the file ends with a newline
        File.write(root.join("REVISION"), "1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b\n")

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

    it "prefers the REVISION file over git, so a release reports what was deployed" do
      in_tmp_root do |root|
        system("git", "init", "--quiet", root.to_s, exception: true)
        File.write(root.join("REVISION"), "1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b\n")

        expect(described_class.short_sha(root:)).to eq "1a2b3c4"
      end
    end

    it "falls back to git in a development checkout, which has no REVISION file" do
      expect(described_class.short_sha(root: Rails.root)).to match(/\A[0-9a-f]{7}\z/)
    end
  end
end
