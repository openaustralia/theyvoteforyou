# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::ClockTime do
  # Every spelling of a time the pipeline meets, from Hansard, the loader and the Division model.
  it "reads each way Hansard and TVFY write a time" do
    { "13:27" => "13:27", "13:27:00" => "13:27", "013:31:00" => "13:31", " 1:31 PM" => "13:31",
      "12:05 AM" => "00:05", "12:30 PM" => "12:30", "9:05 am" => "09:05" }.each do |given, normalised|
      expect(described_class.normalise(given)).to eq(normalised)
    end
  end

  it "prints a twelve-hour time, the same way whatever it was given" do
    expect(%w[13:27 13:27:00 013:27:00].map { |time| described_class.display(time) }).to all(eq("1:27 PM"))
    expect(described_class.display("00:05")).to eq("12:05 AM")
    expect(described_class.display("12:00")).to eq("12:00 PM")
  end

  it "leaves something that is not a time alone" do
    expect(described_class.normalise("later")).to eq("")
    expect(described_class.display(" later ")).to eq("later")
  end
end
