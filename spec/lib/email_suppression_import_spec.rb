# frozen_string_literal: true

require "spec_helper"
require "rake"

# Runs the rake task against a fixture file of fictional addresses.
RSpec.describe "application:email_suppressions:import" do # rubocop:disable RSpec/DescribeClass
  let(:csv) do
    <<~CSV
      address,date,output
      gone@example.org,2026-03-04 05:06:07,550 5.1.1 The email account that you tried to reach does not exist
      Mixed.Case@Example.org,2026-03-05,550-5.1.1 No such user
      blocked@example.org,2026-03-06,550 5.7.1 Our system has detected that this message is suspicious
      blocked-hyphen@example.org,2026-03-06,550-5.7.26 Unauthenticated sender
      silent@example.org,2026-03-07,
      ,2026-03-08,550 5.1.1 No such user
    CSV
  end
  let(:file) { Tempfile.new(["export", ".csv"]).tap { |f| f.write(csv) && f.close } }
  let(:task) { Rake::Task["application:email_suppressions:import"] }

  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?("application:email_suppressions:import")
    task.reenable
  end

  after { file.unlink }

  def run_task
    expect { task.invoke(file.path) }.to output.to_stdout
  end

  it "suppresses addresses that hard-failed, as imported from Postal history" do
    run_task

    expect(EmailSuppression.active.order(:address).pluck(:address, :reason)).to eq(
      [["gone@example.org", "imported_from_postal"], ["mixed.case@example.org", "imported_from_postal"]]
    )
  end

  it "keeps the receiving server's reply and the date of the failure" do
    run_task

    suppression = EmailSuppression.find_by(address: "gone@example.org")
    expect(suppression.reply_excerpt).to start_with("550 5.1.1 The email account")
    expect(suppression.suppressed_at).to eq(Time.zone.parse("2026-03-04 05:06:07"))
  end

  it "leaves out refusals that blame our server, and rows with no reply" do
    run_task

    expect(EmailSuppression.where(address: %w[blocked@example.org blocked-hyphen@example.org silent@example.org])).to be_empty
  end

  it "prints counts only, never an address" do
    counts = a_string_including("Suppressed: 2", "Already suppressed: 0", "Skipped refusal blaming our server: 2",
                                "Skipped no reply: 1", "Skipped no address: 1")
    no_addresses = satisfy { |printed| printed.exclude?("example.org") }

    expect { task.invoke(file.path) }.to output(counts.and(no_addresses)).to_stdout
  end

  it "is safe to run twice" do
    run_task
    task.reenable

    expect { task.invoke(file.path) }.to output(/Suppressed: 0.*Already suppressed: 2/m).to_stdout
    expect(EmailSuppression.count).to eq(2)
  end

  it "does not change an address that is already suppressed" do
    existing = EmailSuppression.suppress!("gone@example.org", reason: :hard_bounce)

    run_task

    expect(EmailSuppression.where(address: "gone@example.org").sole).to eq(existing)
  end
end
