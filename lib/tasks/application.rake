require 'nokogiri'

# TODO: Put this in configuration
XML_DATA_DIRECTORY='/home/henare/tmp/openaustralia/pwdata/members'

namespace :application do
  desc 'memxml2db.pl'
  task reload_member_data: :environment do
    # divisions.xml
    puts "Reloading electorates..."
    puts "Deleted #{Electorate.delete_all} electorates"
    electorates_xml = Nokogiri.parse(File.read("#{XML_DATA_DIRECTORY}/divisions.xml"))
    electorates_xml.search(:division).each do |division|
      Electorate.create!(cons_id: division[:id][/uk.org.publicwhip\/cons\/(\d*)/, 1],
                         # TODO: Support multiple electorate names
                         name: division.at(:name)[:text],
                         main_name: true,
                         from_date: division[:fromdate],
                         to_date: division[:todate],
                         # TODO: Support Scottish parliament
                         house: 'commons')
    end
    puts "Loaded #{Electorate.count} electorates"

    # people.xml
    people_xml = Nokogiri.parse(File.read("#{XML_DATA_DIRECTORY}/people.xml"))
    member_to_person = {}
    people_xml.search(:person).each do |person|
      person.search(:office).each do |office|
        member_to_person[office[:id]] = person[:id]
      end
    end

    # ministers.xml
    puts "Reloading offices..."
    puts "Deleted #{Office.delete_all} offices"
    ministers_xml = Nokogiri.parse(File.read("#{XML_DATA_DIRECTORY}/ministers.xml"))
    ministers_xml.search(:moffice).each do |moffice|
      person = member_to_person[moffice[:matchid]]
      raise "MP #{moffice[:name]} has no person" unless person

      # FIXME: Don't truncate position https://github.com/openaustralia/publicwhip/issues/278
      position = moffice[:position]
      if position.size > 100
        puts "WARNING: Truncating position \"#{position}\""
        position.slice! 0..99
      end

      Office.create!(moffice_id: moffice[:id][/uk.org.publicwhip\/moffice\/(\d*)/, 1],
                     dept: moffice[:dept],
                     position: position,
                     responsibility: (moffice[:responsibility] || ''),
                     from_date: moffice[:fromdate],
                     to_date: moffice[:todate],
                     person: person[/uk.org.publicwhip\/person\/(\d*)/, 1])
    end
    puts "Loaded #{Office.count} offices"

    # TODO: Load representatives.xml
    # TODO: Load senators.xml
    # TODO: Remove Members not found in XML
  end
end
