require 'spec_helper'

describe Policy, type: :model do
  subject { create(:policy) }

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
