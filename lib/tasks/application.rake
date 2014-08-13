# TODO: Put this in configuration
XML_DATA_DIRECTORY='/home/henare/tmp/openaustralia/pwdata/members'

namespace :application do
  namespace :member_data do
    desc "Reloads all relevant data from members XML directory"
    task reload: [:reload_electorates]

    task reload_electorates: :environment do
      puts "Reloading electorates..."
      DataLoader.reload_electorates("#{XML_DATA_DIRECTORY}/divisions.xml")
    end

    # TODO: Load people.xml
    # TODO: Load ministers.xml
    # TODO: Load representatives.xml
    # TODO: Load senators.xml
    # TODO: Remove Members not found in XML
  end
end
