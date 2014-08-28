namespace :application do
  namespace :cache do
    desc 'Update all the caches'
    task :update_all => [:update_member_distances, :update_whip,
      :update_member, :update_division] do
    end

    desc 'Rebuilds the whole cache of agreement between members'
    task :update_member_distances => :environment do
      MemberDistance.update_all!
    end

    desc 'Update cache of guessed whips'
    task :update_whip => :environment do
      puts "Updating cache of guessed whips..."
      Whip.update_all!
    end

    desc "Update cache of member attendance, rebellions, etc"
    task :update_member => :update_whip do
      puts "Updating member cache..."
      MemberInfo.update_all!
    end

    desc "Update cache of division attendance, rebellions, etc"
    task :update_division => :update_whip do
      puts "Updating division cache..."
      DivisionInfo.update_all!
    end
  end

  desc 'Reloads members, offices and electorates from XML files'
  task :reload_member_data => [:environment, :set_logger_to_stdout] do
    DataLoader::Electorates.load!
    DataLoader::Offices.load!
    DataLoader::Members.load!
  end

  desc 'Load divisions from XML for a specified date'
  task :load_divisions_xml, [:from_date, :to_date] => [:environment, :set_logger_to_stdout] do |t, args|
    DataLoader::Debates.load!(from_date: args[:from_date], to_date: args[:to_date])
  end

  task :set_logger_to_stdout do
    Rails.logger = ActiveSupport::Logger.new(STDOUT)
    Rails.logger.level = 1
  end
end
