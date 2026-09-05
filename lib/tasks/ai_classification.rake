# frozen_string_literal: true

namespace :ai do
  desc "Import Policies from theyvoteforyou.org.au's own /api/v1/policies.json output, for local " \
       "dev data (spike, openaustralia/theyvoteforyou#1716). FILE=<path to saved JSON> required."
  task import_policies: :environment do
    file = ENV.fetch("FILE") { abort "Usage: rake ai:import_policies FILE=/path/to/policies.json" }
    owner = User.first || abort("Need at least one User in the dev database to own imported Policies")

    policies = JSON.parse(File.read(file))
    created = 0
    updated = 0
    policies.each do |attrs|
      policy = Policy.find_or_initialize_by(name: attrs["name"])
      policy.user ||= owner
      policy.description = attrs["description"]
      policy.status = attrs["provisional"] ? :provisional : :published
      policy.new_record? ? created += 1 : updated += 1
      policy.save!
    end
    puts "Imported #{policies.size} policies (#{created} created, #{updated} updated)"
  end

  desc "Ask several Bedrock models to classify a Division against existing Policies " \
       "(spike, openaustralia/theyvoteforyou#1716). DIVISION_ID=<id> required."
  task classify_division: :environment do
    division_id = ENV.fetch("DIVISION_ID") { abort "Usage: rake ai:classify_division DIVISION_ID=123" }
    division = Division.find(division_id)

    puts "Division ##{division.id}: #{division.name}"
    puts division.motion.to_s.truncate(200)
    puts

    DivisionPolicyClassifier.new(division).classify_with_all_models.each do |label, result|
      puts "== #{label} =="
      puts result.summary
      puts "  Policy: #{result.policy.name} - #{result.policy.description}" if result.match == "existing" && result.policy
      puts "  Proposed: #{result.new_policy_name} - #{result.new_policy_description}" if result.match == "new"
      puts "  Reasoning: #{result.reasoning}" if result.reasoning
      puts
    end
  end
end
