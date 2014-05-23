require 'spec_helper'

describe EditsController do
  include HTMLCompareHelper
  fixtures :all

  describe '#edits', focus: true do
    it { compare '/edits.php?type=motion&date=2009-11-25&number=8&house=senate' }
    # Disable test where there's actually a diff
    # it { compare '/edits.php?type=motion&date=2013-03-14&number=1&house=representatives' }
  end
end
