namespace :application do
  namespace :cache do
    desc "Update all the caches"
    task all: [:whip, :member, :division, :policy_distances, :member_distances]

    desc "Update all the caches, excluding member_distances (as they take ages)"
    task all_except_member_distances: [:whip, :member, :division, :policy_distances]

    desc "Rebuilds the whole cache of agreement between members"
    task member_distances: :environment do
      puts "Updating member distance cache..."
      MemberDistance.update_all!
    end

    desc "Update cache of guessed whips"
    task whip: :environment do
      puts "Updating cache of guessed whips..."
      Whip.update_all!
    end

    desc "Update cache of member attendance, rebellions, etc"
    task member: :whip do
      puts "Updating member cache..."
      MemberInfo.update_all!
    end

    desc "Update cache of division attendance, rebellions, etc"
    task division: :whip do
      puts "Updating division cache..."
      DivisionInfo.update_all!
    end

    desc "Update cache of guessed whips"
    task policy_distances: :environment do
      puts "Updating policy distance cache..."
      Policy.update_all!
    end
  end

  namespace :load do
    desc "Reloads members, offices and electorates from XML files and updates people images"
    task members: [:environment, :set_logger_to_stdout] do
      DataLoader::Electorates.load!
      DataLoader::Offices.load!
      DataLoader::Members.load!
      DataLoader::People.load_missing_images!
    end

    desc "Load divisions from XML for a specified date"
    task :divisions, [:from_date, :to_date] => [:environment, :set_logger_to_stdout] do |t, args|
      if args[:to_date]
        DataLoader::Debates.load!(Date.parse(args[:from_date]), Date.parse(args[:to_date]))
      else
        DataLoader::Debates.load!(Date.parse(args[:from_date]))
      end
    end

    desc "Reload members, offices and electorates - load yesterday's divisions - update caches"
    task daily: :environment do
      # Get yesterday's system date to avoid Rails UTC timezone
      yesterday = Time.now.yesterday.to_date.to_s

      task("application:load:members").invoke
      task("application:load:divisions").invoke(yesterday)
      task("application:cache:all").invoke
    end

    desc "Load Popolo data from a URL"
    task :popolo, [:url] => [:environment, :set_logger_to_stdout] do |t, args|
      DataLoader::Popolo.load!(args[:url])
    end
  end

  namespace :seed do
    desc " WARNING deletes data: Create db/seed.rb sample data to make the life of the developer a joyous one"
    task create: :environment do
      FileUtils.rm_rf("db/seeds.rb")
      Rake::Task["db:reset"].invoke
      Rake::Task["application:load:members"].invoke
      # Just load divisions from 13 Feb 2014
      Rake::Task["application:load:divisions"].invoke("2014-02-13")
      # Let's prune the members down to two in each house
      puts "Pruning (or should I say culling?) members..."
      members = Member.in_house("senate").current_on(Date.today).limit(2) +
        Member.in_house("representatives").current_on(Date.today).limit(2)
      Member.find_each {|member| member.destroy unless members.include?(member)}
      Rake::Task["application:cache:all"].invoke
      # TODO This doesn't yet create policy information nor edited motion text
      File.open("db/seeds.rb", "w") do |f|
        f.write("PaperTrail.whodunnit = User.create!(email:'matthew@oaf.org.au', name: 'Matthew Landauer', password: 'foofoofoo', confirmed_at: Time.now)\n")
      end
      [Division, DivisionInfo, Electorate, Member, MemberDistance, MemberInfo, Office, Person, Policy, PolicyDivision, PolicyPersonDistance, Vote, Whip].each do |records|
        SeedDump.dump(records.all, file: "db/seeds.rb", append: true, exclude: [:created_at, :updated_at])
      end
    end
  end

  namespace :config do
    task :dev do
      %w(
        config/database.yml
        config/secrets.yml
      ).each do |target|
        source = "#{target}.example"
        if not File.exist?(Rails.root.join(target))
          FileUtils.cp(
            Rails.root.join(source),
            Rails.root.join(target)
          )
          puts "#{source} => #{target}"
        else
          puts "#{target} already exists."
        end
      end
    end
  end

  namespace :divisions do
    desc "Convert all divisions motion text to markdown if possible"
    task markdown: :environment do
      include PathHelper

      Division.where(markdown: false).find_each do |division|
        if division.edited?
          # TODO Don't convert divisions with voting actions, comments or footnotes
          if division.motion =~ /\[(\d+)\]/
            puts "Can not convert motion text to markdown because it contains footnotes: #{division_path(division)}"
          elsif division.motion =~ /^@/
            puts "Can not convert motion text to markdown because it contains comments or voting actions: #{division_path(division)}"
          else
            new_motion = ReverseMarkdown.convert(division.formatted_motion_text)
            if new_motion != division.motion
              puts "Converting #{division_path(division)} to Markdown..."
              division.transaction do
                division.update_attributes(markdown: true)
                division.create_wiki_motion! division.name, new_motion, User.system
              end
            end
          end
        else
          puts "Setting unedited division #{division.name} to use Markdown"
          division.update_attributes(markdown: true)
        end
      end
    end

    desc "Inline any footnotes on division motions"
    task inline_footnotes: :environment do
      include PathHelper

      Division.where(markdown: false).find_each do |division|
        if division.edited? && division.motion =~ /\[(\d+)\]/
          puts "Inlining footnotes on #{division_path(division)}..."
          new_motion = Division.inline_footnotes(division.motion)
          division.create_wiki_motion! division.name, new_motion, User.system
        end
      end
      puts "Please NOTE: Go through divisions and tidy up manually. Automatic inlining has some limitations."
    end
  end

  task :set_logger_to_stdout do
    Rails.logger = ActiveSupport::Logger.new(STDOUT)
    Rails.logger.level = 1
  end
end
