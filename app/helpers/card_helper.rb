module CardHelper
    def get_hostname(url)
      uri = URI(url)
      uri.hostname 
    # url.sub("http://", "")
    end

    def remove_slash(link)
        link.sub("//", "/")
    end
end