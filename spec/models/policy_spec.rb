require 'spec_helper'

describe Policy, type: :model do
  subject { create(:policy) }

  it 'is valid with a name longer than 50 characters' do
    user = create(:user)
    policy = build(:policy, user: user, name:  'a-name-much-bigger-than-fifty-characters-a-very-long-name-indeed')

    expect(policy).to be_valid
  end

  it 'is not valid with a name longer than 100 characters' do
    policy = build(:policy, name: 'a-name-bigger-than-one-hundred-characters-is-such-a-long-name-for-a-policy-is-it-really-necessay? We’ll find out soon.')

    expect(policy).to be_invalid
    expect(policy.errors[:name]).to include("is too long (maximum is 100 characters)")
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
