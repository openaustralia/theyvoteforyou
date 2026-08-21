# frozen_string_literal: true

require Rails.root.join("app/helpers/path_helper")

# Cron schedules are defined in the OAF infrastructure repo (ansible role
# roles/internal/theyvoteforyou) - that's the source of truth for the crontabs below.
def with_sentry_cron_monitoring(slug, crontab, &block)
  return block.call unless defined?(Sentry) && Sentry.initialized?

  monitor_config = Sentry::Cron::MonitorConfig.from_crontab(
    crontab,
    checkin_margin: 60,
    max_runtime: 360,
    timezone: "Australia/Sydney"
  )
  check_in_id = Sentry.capture_check_in(slug, :in_progress, monitor_config: monitor_config)
  # Rake tasks run outside any automatic Sentry transaction, so start one here
  # to make the sentry_stage spans visible in a trace. sampled: true because
  # these run once a day - the web traces_sample_rate would drop most runs.
  transaction = Sentry.start_transaction(name: slug, op: "cron", sampled: true)
  Sentry.get_current_scope.set_span(transaction) if transaction
  start = Sentry.utc_now
  begin
    block.call
    transaction&.set_status("ok")
    Sentry.capture_check_in(slug, :ok, check_in_id: check_in_id, duration: Sentry.utc_now - start,
                                       monitor_config: monitor_config)
  rescue StandardError
    transaction&.set_status("internal_error")
    Sentry.capture_check_in(slug, :error, check_in_id: check_in_id, duration: Sentry.utc_now - start,
                                          monitor_config: monitor_config)
    raise
  ensure
    transaction&.finish
  end
end

# Wrap a stage of a cron run in a child span so the trace shows where the time
# goes. Safely a no-op when there's no active transaction (e.g. running a task
# by hand) or Sentry isn't initialized.
def sentry_stage(name, &block)
  return block.call unless defined?(Sentry)

  Sentry.with_child_span(op: "task", description: name) { |_span| block.call }
end

namespace :application do
  namespace :cache do
    desc "Update all the caches"
    task all: %i[whip member division policy_distances people_distances]

    desc "Update all the caches, excluding people_distances (as they take ages)"
    task all_except_people_distances: %i[whip member division policy_distances]

    desc "Rebuilds the whole cache of agreement between people"
    task people_distances: :environment do
      sentry_stage("application:cache:people_distances") do
        people = Person.all
        progressbar = ProgressBar.create(title: "Updating people distance cache", total: people.count, format: "%t: |%B| %E %a")
        people.find_each do |person|
          PeopleDistance.update_person(person)
          progressbar.increment
        end
      end
    end

    desc "Update cache of guessed whips"
    task whip: :environment do
      sentry_stage("application:cache:whip") do
        puts "Updating cache of guessed whips..."
        Whip.update_all!
      end
    end

    desc "Update cache of member attendance, rebellions, etc"
    task member: :whip do
      sentry_stage("application:cache:member") do
        puts "Updating member cache..."
        MemberInfo.update_all!
      end
    end

    desc "Update cache of division attendance, rebellions, etc"
    task division: :whip do
      sentry_stage("application:cache:division") do
        puts "Updating division cache..."
        DivisionInfo.update_all!
      end
    end

    desc "Update cache of policy distances"
    task policy_distances: :environment do
      sentry_stage("application:cache:policy_distances") do
        policies = Policy.all
        progressbar = ProgressBar.create(title: "Updating policy distance cache", total: policies.count, format: "%t: |%B| %E %a")
        policies.find_each do |policy|
          policy.calculate_person_distances!
          progressbar.increment
        end
      end
    end

    # See https://github.com/openaustralia/theyvoteforyou/issues/1478 for an explanation of how
    # an incorrect member can be attached to a vote, the effect it has and how this fixes it.
    desc "Fix member attached to votes"
    task member_vote_fix: :environment do
      sentry_stage("application:cache:member_vote_fix") do
        Vote.includes(:division, :member).find_each do |vote|
          if vote.division.nil?
            puts "WARNING: Vote #{vote.id} points to non-existent division"
            next
          end
          unless vote.member.could_have_voted_in_division?(vote.division)
            puts "Vote #{vote.id} has an incorrect member. Fixing"
            # Find the member who could have voted on this division
            vote.member = vote.member.person.member_in_division(vote.division)
            if vote.member.nil?
              puts "WARNING: Couldn't find a member to fix vote #{vote.id} with division #{vote.division_id}. vote = #{vote.inspect}"
              next
            end
            vote.save!
          end
        end
      end
    end
  end

  namespace :cron do
    desc "Run this every night. Generates screenshots"
    task nightly: :environment do
      with_sentry_cron_monitoring("application-cron-nightly", "5 2 * * *") do
        task("application:cards:all").invoke
      end
    end
  end

  namespace :load do
    desc "Reloads members, offices and electorates from XML files and updates people images"
    task members: %i[environment set_logger_to_stdout] do
      sentry_stage("DataLoader::Electorates.load!") { DataLoader::Electorates.load! }
      sentry_stage("DataLoader::Members.load!") { DataLoader::Members.load! }
      # This fixes up members attached to votes
      task("application:cache:member_vote_fix").invoke
      # Offices need to be loaded after new people/members
      sentry_stage("DataLoader::Offices.load!") { DataLoader::Offices.load! }
      sentry_stage("DataLoader::People.load_missing_images!") { DataLoader::People.load_missing_images! }
    end

    desc "Load divisions from XML for a specified date"
    task :divisions, %i[from_date to_date] => %i[environment set_logger_to_stdout] do |_t, args|
      sentry_stage("application:load:divisions") do
        if args[:to_date]
          DataLoader::Debates.load!(Date.parse(args[:from_date]), Date.parse(args[:to_date]))
        else
          DataLoader::Debates.load!(Date.parse(args[:from_date]))
        end
      end
    end

    desc "Reload members, offices and electorates - load yesterday's divisions - update caches"
    task daily: :environment do
      with_sentry_cron_monitoring("application-load-daily", "15 9 * * 1-5") do
        # Get yesterday's system date to avoid Rails UTC timezone
        yesterday = Time.zone.now.yesterday.to_date.to_s

        task("application:load:members").invoke
        task("application:load:divisions").invoke(yesterday)
        task("application:cache:all").invoke
      end
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
      [Division, DivisionInfo, Electorate, Member, PeopleDistance, MemberInfo, Office, Person, Policy, PolicyDivision, PolicyPersonDistance, Vote, Whip].each do |records|
        SeedDump.dump(records.all, file: "db/seeds.rb", append: true, exclude: %i[created_at updated_at])
      end
    end
  end

  namespace :config do
    task dev: :environment do
      %w[
        config/database.yml
      ].each do |target|
        source = "#{target}.example"
        if Rails.root.join(target).exist?
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

  namespace :cards do
    desc "Generate all social media sharing cards"
    task all: %i[policies people person_policies person_policies_category policies_category]

    desc "Generate social media cards for how people vote on particular policies"
    task person_policies: :environment do
      sentry_stage("application:cards:person_policies") { CardScreenshotter::PersonPolicies.run }
    end

    desc "Generate social media cards for people"
    task people: :environment do
      sentry_stage("application:cards:people") { CardScreenshotter::Members.run }
    end

    desc "Generate social media cards for each category a member votes"
    task person_policies_category: :environment do
      sentry_stage("application:cards:person_policies_category") { CardScreenshotter::MemberPolicyCategory.run }
    end

    desc "Generate social media cards for policies"
    task policies: :environment do
      sentry_stage("application:cards:policies") { CardScreenshotter::Policies.run }
    end

    desc "Generate social media cards for each category on a policy"
    task policies_category: :environment do
      sentry_stage("application:cards:policies_category") { CardScreenshotter::PoliciesCategory.run }
    end
  end
end
