class WikiParser < WikiCloth::Parser
  external_link do |url,text|
    %(<a href="#{url}">#{text.blank? ? url : text}</a>)
  end
end
