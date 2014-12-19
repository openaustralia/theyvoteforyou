require 'spec_helper'

describe Policy, type: :model do
  subject { create(:policy) }

  describe '#status' do
    it 'status is 0' do
      subject.status = 0
      expect(subject.status).to eql 'published'
    end

    it 'status is 1' do
      subject.status = 1
      expect(subject.status).to eql 'legacy Dream MP'
    end

    it 'status is 2' do
      subject.status = 2
      expect(subject.status).to eql 'provisional'
    end
  end

  describe '#provisional?' do
    it 'status is 2' do
      subject.status = 2
      expect(subject.provisional?).to eql true
    end

    it 'status is 0' do
      subject.status = 0
      expect(subject.provisional?).to eql false
    end
  end
end
