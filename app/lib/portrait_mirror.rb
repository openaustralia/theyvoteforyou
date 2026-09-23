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
  # Thousands of portraits are fetched in series, so one stalled host must not
  # hold the nightly run for Net::HTTP's default 60 seconds each
  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 30

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
      # A challenge or error page served with a 200 must not replace a real portrait
      if response.content_type.to_s.start_with?("image/")
        write(response.body)
      else
        record_failure("unexpected content type #{response.content_type.inspect}")
      end
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
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                        open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
      http.request(request)
    end
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
