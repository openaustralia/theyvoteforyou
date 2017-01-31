require 'spec_helper'

describe Policy, type: :model do
  subject { create(:policy) }

  it 'is not valid with a name longer than 50 characters' do
    policy = Policy.new
    policy.name = 'a-name-much-bigger-than-fifty-characters-a-very-long-name-indeed'
    policy.valid?
    expect(policy.errors[:name]).to include("is too long (maximum is 50 characters)")
  end

  describe '#status' do
    it 'private is 0' do
      subject.private = 0
      expect(subject.status).to eql 'published'
    end

    it 'private is 1' do
      subject.private = 1
      expect(subject.status).to eql 'legacy Dream MP'
    end

    it 'private is 2' do
      subject.private = 2
      expect(subject.status).to eql 'provisional'
    end
  end

  describe '#provisional?' do
    it 'private is 2' do
      subject.private = 2
      expect(subject.provisional?).to eql true
    end

    it 'private is 0' do
      subject.private = 0
      expect(subject.provisional?).to eql false
    end
  end
end
