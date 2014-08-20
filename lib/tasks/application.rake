namespace :application do
  desc 'Rebuilds the whole cache of agreement between members'
  task :update_member_distances_cache => :environment do
    MemberDistance.update_all!
  end

  desc 'Reloads members, offices and electorates from XML files'
  task :reload_member_data, [:xml_data_directory] => :environment do |t, args|
    Rails.logger = ActiveSupport::Logger.new(STDOUT)
    Rails.logger.level = 1
    loader = XMLDataLoader.new(args[:xml_data_directory])
    loader.load_all
  end

  desc 'Update cache of guessed whips'
  task :update_whip_cache => :environment do
    Whip.update_all!
  end

  desc 'Load divisions from XML for a specified date'
  task :load_divisions_xml, [:xml_data_directory, :date] => :environment do |t, args|
    House.australian.each do |house|
      parser = DebatesXML::Parser.new("#{args[:xml_data_directory]}/#{house}_debates/#{args[:date]}.xml", House.australian_to_uk(house))
      parser.divisions.each do |division|
        puts "Saving division: #{division.house} #{division.date} #{division.number}"
        division.save!
      end
    end
  end
end
