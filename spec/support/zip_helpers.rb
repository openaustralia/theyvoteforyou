# frozen_string_literal: true

require "zip"

# Builds a zip of draft files for specs: a hash of path inside the zip => contents.
module ZipHelpers
  def build_zip(files)
    path = Rails.root.join("tmp/test_zips/#{SecureRandom.hex(4)}.zip")
    FileUtils.mkdir_p(path.dirname)
    Zip::OutputStream.open(path.to_s) do |zip|
      files.each do |name, contents|
        zip.put_next_entry(name)
        zip.write(contents)
      end
    end
    path
  end

  def uploaded_zip(files)
    Rack::Test::UploadedFile.new(build_zip(files), "application/zip")
  end
end

RSpec.configure do |config|
  config.include ZipHelpers
  config.after { FileUtils.rm_rf(Rails.root.join("tmp/test_zips")) }
end
