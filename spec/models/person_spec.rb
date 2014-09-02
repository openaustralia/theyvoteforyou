require 'spec_helper'

describe Person, :type => :model do
  context "Anthony Albanese" do
    let (:person) { Person.new(id: 10007)}

    describe ".large_image_url" do
      it {expect(person.large_image_url).to eq "http://www.openaustralia.org/images/mpsL/10007.jpg"}
    end

    describe ".small_image_url" do
      it {expect(person.small_image_url).to eq "http://www.openaustralia.org/images/mps/10007.jpg"}
    end
  end
end
