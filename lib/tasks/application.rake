namespace :application do
  desc 'Rebuilds the whole cache of agreement between members'
  task :update_member_distances_cache => :environment do
    MemberDistance.update_all!
  end

  desc 'Reloads members, offices and electorates from XML files'
  task :reload_member_data => [:environment, :set_logger_to_stdout] do |t, args|
    DataLoader::MembersXML.load_all
  end

  desc 'Update all the caches'
  task :update_caches => [:update_member_distances_cache, :update_whip_cache,
    :update_member_cache, :update_division_cache] do
  end

  desc 'Update cache of guessed whips'
  task :update_whip_cache => :environment do
    puts "Updating cache of guessed whips..."
    Whip.update_all!
  end

  desc "Update cache of member attendance, rebellions, etc"
  task :update_member_cache => :update_whip_cache do
    puts "Updating member cache..."
    MemberInfo.update_all!
  end

  desc "Update cache of division attendance, rebellions, etc"
  task :update_division_cache => :update_whip_cache do
    puts "Updating division cache..."
    DivisionInfo.update_all!
  end

  desc 'Load divisions from XML for a specified date'
  task :load_divisions_xml, [:date, :house] => [:environment, :set_logger_to_stdout] do |t, args|
    DataLoader::Debates.load!(date: args[:date], house: args[:house])
  end

  task :set_logger_to_stdout do
    Rails.logger = ActiveSupport::Logger.new(STDOUT)
    Rails.logger.level = 1
  end
end
