require 'spec_helper'

describe Policy, type: :model do
  subject { create(:policy) }

  describe '#status' do
    it 'private is 0' do
      subject.private = 0
      expect(subject.status).to eql 'public'
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
end
