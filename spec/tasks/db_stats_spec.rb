# frozen_string_literal: true

require "spec_helper"
require "rake"

describe "db:stats" do # rubocop:disable RSpec/DescribeClass
  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["db:stats"].reenable
  end

  it "lists each table with its count, and the total" do
    create(:user)
    expect { Rake::Task["db:stats"].invoke }
      .to output(/^users\s+1\s+[\d.]+ MB$.*^TOTAL\s+\d+\s+[\d.]+ MB$.*approximate count/m).to_stdout
  end

  it "counts every table exactly with EXACT_COUNT set" do
    stub_const("ENV", ENV.to_h.merge("EXACT_COUNT" => "1"))
    expect { Rake::Task["db:stats"].invoke }.to output(/\(exact count\)/).to_stdout
  end
end
