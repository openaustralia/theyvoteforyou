namespace :application do
  desc 'Rebuilds the whole cache of agreement between members'
  task :update_member_distances_cache => :environment do
    MemberDistance.update_all!
  end
end
