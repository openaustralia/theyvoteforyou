# frozen_string_literal: true

require "net/http"

# Copies each person's portrait from its source URL (see Person#*_image_url)
# into public/system/portraits so the site serves them itself rather than
# hot-linking them. Runs nightly and whenever a new portrait URL is
# discovered. Uses If-Modified-Since so unchanged portraits cost a 304.
#
# A failed download never removes an existing file: a stale portrait is
# better than none. See docs/adr/0004-mirror-portraits-rather-than-hot-link-them.md
class PortraitMirror
  SIZES = %i[small large extra_large].freeze
  ROOT = Rails.public_path.join("system/portraits")

  def self.run
    Person.find_each { |person| mirror(person) }
  end

  def self.mirror(person)
    SIZES.each do |size|
      source = person.public_send(:"#{size}_image_source_url")
      new(source, path_for(size, person.id)).mirror if source
    end
  end

  def self.path_for(size, person_id)
    ROOT.join(size.to_s, "#{person_id}.jpg")
  end

  def initialize(source, path)
    @source = source
    @path = path
  end

  def mirror
    response = fetch
    case response
    when Net::HTTPSuccess
      write(response.body)
    when Net::HTTPNotModified
      nil
    else
      record_failure("HTTP #{response.code}")
    end
  rescue StandardError => e
    record_failure(e.message)
  end

  private

  attr_reader :source, :path

  def fetch
    uri = URI(source)
    request = Net::HTTP::Get.new(uri)
    request["If-Modified-Since"] = File.mtime(path).httpdate if File.exist?(path)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) }
  end

  # Write to a temp file in the same directory then rename, so a reader never
  # sees a half-written portrait and a failure leaves the old file in place.
  def write(body)
    FileUtils.mkdir_p(path.dirname)
    Tempfile.create("portrait", path.dirname) do |tmp|
      tmp.binmode
      tmp.write(body)
      tmp.flush
      File.rename(tmp.path, path)
    end
  end

  def record_failure(reason)
    Rails.logger.warn("Could not mirror portrait #{source}: #{reason}")
    Sentry::Metrics.count("portraits.mirror.failed")
  end
end
