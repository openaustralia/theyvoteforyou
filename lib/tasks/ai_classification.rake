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

  desc "Ask several Bedrock models to classify a Division against existing Policies, saving each " \
       "as an AiPolicySuggestion - skips any model already saved for this Division " \
       "(spike, openaustralia/theyvoteforyou#1716). DIVISION_ID=<id> required."
  task classify_division: :environment do
    division_id = ENV.fetch("DIVISION_ID") { abort "Usage: rake ai:classify_division DIVISION_ID=123" }
    division = Division.find(division_id)
    classifier = DivisionPolicyClassifier.new(division)

    puts "Division ##{division.id}: #{division.name}"
    puts division.motion.to_s.truncate(200)
    puts

    DivisionPolicyClassifier::MODELS.each do |label, model_id|
      suggestion = AiPolicySuggestion.find_by(division: division, model: model_id, error: nil)
      if suggestion
        puts "== #{label} (already classified, skipping) =="
      else
        result = classifier.classify_with(model_id)
        suggestion = AiPolicySuggestion.create_from_result!(division, result)
        puts "== #{label} =="
      end

      puts suggestion.summary
      puts "  Policy: #{suggestion.policy.name} - #{suggestion.policy.description}" if suggestion.match == "existing" && suggestion.policy
      puts "  Proposed: #{suggestion.proposed_policy_name} - #{suggestion.proposed_policy_description}" if suggestion.match == "new"
      puts "  Reasoning: #{suggestion.reasoning}" if suggestion.reasoning
      puts
    end
  end

  desc "Ask several Bedrock models to write a plain-language title and description for a " \
       "Division, saving each as an AiDivisionSummary - skips any model already saved for this " \
       "Division (spike, openaustralia/theyvoteforyou#1716). DIVISION_ID=<id> required."
  task summarize_division: :environment do
    division_id = ENV.fetch("DIVISION_ID") { abort "Usage: rake ai:summarize_division DIVISION_ID=123" }
    division = Division.find(division_id)
    summarizer = DivisionSummarizer.new(division)

    puts "Division ##{division.id}: #{division.name}"
    puts division.motion.to_s.truncate(200)
    puts

    DivisionSummarizer::MODELS.each do |label, model_id|
      summary = AiDivisionSummary.find_by(division: division, model: model_id)
      if summary && summary.error.blank?
        puts "== #{label} (already summarised, skipping) =="
      else
        result = summarizer.summarize_with(model_id)
        summary = AiDivisionSummary.save_from_result!(division, result)
        puts "== #{label} =="
      end

      if summary.error
        puts "Error: #{summary.error}"
      else
        puts "Title: #{summary.title}"
        puts "Description: #{summary.description}"
      end
      puts
    end
  end
end
