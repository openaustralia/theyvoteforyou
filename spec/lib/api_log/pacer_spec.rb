# frozen_string_literal: true

require "spec_helper"

describe ApiLog::Pacer do
  let(:pacer) { described_class.new(gap: 0.05) }

  before { allow(described_class).to receive(:pause) }

  it "doesn't wait before the first call" do
    pacer.call { :done }
    expect(described_class).not_to have_received(:pause)
  end

  it "returns what the call returns" do
    expect(pacer.call { :done }).to eq :done
  end

  it "waits at least as long as the last call took, plus the gap" do
    pacer.call { sleep 0.05 }
    pacer.call { :done }
    expect(described_class).to have_received(:pause).with(a_value_between(0.09, 0.11))
  end

  it "counts time spent elsewhere towards the wait" do
    pacer.call { sleep 0.05 }
    sleep 0.2
    pacer.call { :done }
    expect(described_class).not_to have_received(:pause)
  end

  it "adds up how long it has waited" do
    pacer.call { :done }
    pacer.call { :done }
    expect(pacer.waited).to be_within(0.01).of(0.05)
  end
end
