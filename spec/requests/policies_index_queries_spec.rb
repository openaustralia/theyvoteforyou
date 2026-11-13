# frozen_string_literal: true

require "spec_helper"

# The list pages render a summary line per policy, so the number of queries must not grow with the number of policies.
describe "Policy list query count", type: :request do
  def count_queries(&)
    count = 0
    counter = lambda do |*, payload|
      count += 1 unless payload[:name] == "SCHEMA" || payload[:cached]
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    count
  end

  def create_policies(number, factory)
    user = create(:user)
    create_list(factory, number, user: user).each do |policy|
      edited = create(:division)
      create(:wiki_motion, division: edited)
      create(:policy_division, policy: policy, division: edited)
      create(:policy_division, policy: policy, division: create(:division))
      create(:policy_division, policy: policy, division: create(:division))
      create_list(:user, 2).each { |watcher| Watch.create!(watchable: policy, user: watcher) }
    end
  end

  def queries_for(path, factory, number)
    Policy.destroy_all
    create_policies(number, factory)
    get path # warm up anything that is loaded once per process
    count_queries { get path }
  end

  {
    "/policies" => :policy,
    "/policies?sort=name" => :policy,
    "/policies?sort=date" => :policy,
    "/policies/drafts" => :provisional_policy
  }.each do |path, factory|
    it "does not grow with the number of policies on #{path}" do
      expect(queries_for(path, factory, 12)).to eq(queries_for(path, factory, 3))
    end
  end
end
