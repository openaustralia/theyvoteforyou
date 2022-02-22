# frozen_string_literal: true

module CardHelper
  def get_hostname(url)
    uri = URI(url)
    uri.hostname
  end

  def remove_slash(link)
    link.sub("//", "/")
  end
end
