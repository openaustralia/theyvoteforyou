require "spec_helper"

describe Parliament, type: :model do
  describe "#latest" do
    it {expect(Parliament.latest).to eq "2013"}
  end
end
