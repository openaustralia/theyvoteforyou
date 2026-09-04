# frozen_string_literal: true

namespace :ai do
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
      puts "  Proposed: #{result.new_policy_name} - #{result.new_policy_description}" if result.match == "new"
      puts "  Reasoning: #{result.reasoning}" if result.reasoning
      puts
    end
  end
end
