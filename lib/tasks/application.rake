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

  desc "Update cache of member attendance, rebellions, etc"
  task :update_member_cache => :environment do
    MemberInfo.update_all!
  end

  desc "Update cache of division attendance, rebellions, etc"
  task :update_division_cache => :environment do
    DivisionInfo.update_all!
  end
end
