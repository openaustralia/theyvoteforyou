# frozen_string_literal: true

require Rails.root.join("app/helpers/path_helper")

namespace :application do
  namespace :cache do
    desc "Update all the caches"
    task all: %i[whip member division policy_distances member_distances]

    desc "Update all the caches, excluding member_distances (as they take ages)"
    task all_except_member_distances: %i[whip member division policy_distances]

    desc "Rebuilds the whole cache of agreement between members"
    task member_distances: :environment do
      members = Member.all
      progressbar = ProgressBar.create(title: "Updating member distance cache", total: members.count, format: "%t: |%B| %E %a")
      members.find_each do |member|
        MemberDistance.update_member(member)
        progressbar.increment
      end
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

    desc "Update cache of policy distances"
    task policy_distances: :environment do
      policies = Policy.all
      progressbar = ProgressBar.create(title: "Updating policy distance cache", total: policies.count, format: "%t: |%B| %E %a")
      policies.find_each do |policy|
        policy.calculate_person_distances!
        progressbar.increment
      end
    end
  end

  namespace :load do
    desc "Reloads members, offices and electorates from XML files and updates people images"
    task members: %i[environment set_logger_to_stdout] do
      DataLoader::Electorates.load!
      DataLoader::Members.load!
      # Offices need to be loaded after new people/members
      DataLoader::Offices.load!
      DataLoader::People.load_missing_images!
    end

    desc "Load divisions from XML for a specified date"
    task :divisions, %i[from_date to_date] => %i[environment set_logger_to_stdout] do |_t, args|
      if args[:to_date]
        DataLoader::Debates.load!(Date.parse(args[:from_date]), Date.parse(args[:to_date]))
      else
        DataLoader::Debates.load!(Date.parse(args[:from_date]))
      end
    end

    desc "Reload members, offices and electorates - load yesterday's divisions - update caches"
    task daily: :environment do
      # Get yesterday's system date to avoid Rails UTC timezone
      yesterday = Time.zone.now.yesterday.to_date.to_s

      task("application:load:members").invoke
      task("application:load:divisions").invoke(yesterday)
      task("application:cache:all").invoke
    end

    desc "Load Popolo data from a URL"
    task :popolo, [:url] => %i[environment set_logger_to_stdout] do |_t, args|
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
      members = Member.in_house("senate").current_on(Time.zone.today).limit(2) +
                Member.in_house("representatives").current_on(Time.zone.today).limit(2)
      Member.find_each { |member| member.destroy unless members.include?(member) }
      Rake::Task["application:cache:all"].invoke
      # TODO: This doesn't yet create policy information nor edited motion text
      File.write(
        "db/seeds.rb",
        "PaperTrail.whodunnit = User.create!(email:'matthew@oaf.org.au', name: 'Matthew Landauer', password: 'foofoofoo', confirmed_at: Time.now)\n"
      )
      [Division, DivisionInfo, Electorate, Member, MemberDistance, MemberInfo, Office, Person, Policy, PolicyDivision, PolicyPersonDistance, Vote, Whip].each do |records|
        SeedDump.dump(records.all, file: "db/seeds.rb", append: true, exclude: %i[created_at updated_at])
      end
    end
  end

  namespace :config do
    task dev: :environment do
      %w[
        config/database.yml
        config/secrets.yml
      ].each do |target|
        source = "#{target}.example"
        if File.exist?(Rails.root.join(target))
          puts "#{target} already exists."
        else
          FileUtils.cp(
            Rails.root.join(source),
            Rails.root.join(target)
          )
          puts "#{source} => #{target}"
        end
      end
    end
  end

  task set_logger_to_stdout: :environment do
    Rails.logger = ActiveSupport::Logger.new($stdout)
    Rails.logger.level = 1
  end

  namespace :links_valid do
    desc "Checks the validity of links in division summary"
    task divisions: :environment do
      include PathHelper
      include Rails.application.routes.url_helpers

      # Checks if URL goes to a working web page by doing an actual web requests
      # Caches results so multiple requests don't get made to the same URL
      def broken_url?(url)
        @broken ||= {}
        @broken[url] = broken_url_no_caching?(url) unless @broken.key?(url)
        @broken[url]
      end

      def broken_url_no_caching?(url)
        begin
          result = HTTParty.get(url)
        rescue StandardError
          return true
        end
        # Anything that is not a 200 we consider broken
        # Redirects are handled by HTTParty so they can be ignored here
        result.code != 200
      end

      Division.find_each do |division|
        broken_urls = []

        tags = Nokogiri::HTML.parse(division.formatted_motion_text).xpath("//a")
        tags.each do |tag|
          broken_urls << tag[:href] if broken_url?(tag[:href])
        end
        unless broken_urls.empty?
          # Horrible hack to get same host and protocol settings as used by the mailer
          puts "There are broken links in the description for division #{division_url_simple(division, ActionMailer::Base.default_url_options)}"
          broken_urls.each do |broken_url|
            puts "\t#{broken_url}"
          end
        end
      end
    end
  end

  namespace :generate do
    desc "A task to capture all screenshots of the social media sharing cards"
    task cards: :environment do
      # TODO: These should really be included in CardScreenshotter::Members
      include Rails.application.routes.url_helpers
      include PathHelper
      CardScreenshotter::Members.update_screenshots
    end
  end
end
