# frozen_string_literal: true

include Rails.application.routes.url_helpers

namespace :application do
  namespace :cache do
    desc "Update all the caches"
    task all: %i[whip member division policy_distances member_distances]

    desc "Update all the caches, excluding member_distances (as they take ages)"
    task all_except_member_distances: %i[whip member division policy_distances]

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

    desc "Update cache of policy distances"
    task policy_distances: :environment do
      puts "Updating policy distance cache..."
      Policy.update_all!
    end
  end

  namespace :load do
    desc "Reloads members, offices and electorates from XML files and updates people images"
    task members: %i[environment set_logger_to_stdout] do
      DataLoader::Electorates.load!
      DataLoader::Offices.load!
      DataLoader::Members.load!
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
      md = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

      Division.find_each do |division|
        wiki_motion = division.wiki_motion

        if wiki_motion
          summary_in_html = md.render(wiki_motion.description)
          parsed_data = Nokogiri::HTML.parse(summary_in_html)
          url_hash_table = Hash.new(0)
          broken_urls = []

          tags = parsed_data.xpath("//a")
          tags.each do |tag|
            url_from_page = tag[:href]
            url = url_from_page

            begin
              if (url_hash_table[url]).zero?
                url_hash_table[url] += 1
                uri = URI(url)
                Net::HTTP.get(uri)
              end
            rescue StandardError
              broken_urls << url_from_page
            end
          end
          puts "There are broken links in the description for division #{division_url(division)}"
          broken_urls.each do |broken_url|
            puts "\t#{broken_url}"
          end
        end
      end
    end
  end
end
