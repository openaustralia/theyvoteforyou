require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe DivisionsController, :type => :request do
  include HTMLCompareHelper
  fixtures :all

  it "#show" do
    compare_static("/division.php?date=2013-03-14&number=1")
    compare_static("/division.php?date=2013-03-14&number=1&house=representatives")
    compare_static("/division.php?date=2013-03-14&number=1&house=senate")
    compare_static("/division.php?date=2013-03-14&number=1&display=allvotes")
    compare_static("/division.php?date=2013-03-14&number=1&house=representatives&display=allvotes")
    compare_static("/division.php?date=2013-03-14&number=1&house=senate&display=allvotes")
    compare_static("/division.php?date=2013-03-14&number=1&display=allpossible")
    compare_static("/division.php?date=2013-03-14&number=1&house=representatives&display=allpossible")
    compare_static("/division.php?date=2013-03-14&number=1&house=senate&display=allpossible")
    compare_static("/division.php?date=2013-03-14&number=1&display=policies", false, false, "_2")
    compare_static("/division.php?date=2013-03-14&number=1&house=representatives&display=policies", false, false, "_2")
    compare_static("/division.php?date=2013-03-14&number=1&house=senate&display=policies", false, false, "_2")
    compare_static("/division.php?date=2013-03-14&number=1&sort=name")
    compare_static("/division.php?date=2013-03-14&number=1&house=representatives&sort=name")
    compare_static("/division.php?date=2013-03-14&number=1&house=senate&sort=name")
    compare_static("/division.php?date=2013-03-14&number=1&display=allvotes&sort=name")
    compare_static("/division.php?date=2013-03-14&number=1&house=representatives&display=allvotes&sort=name")
    compare_static("/division.php?date=2013-03-14&number=1&house=senate&display=allvotes&sort=name")
    compare_static("/division.php?date=2013-03-14&number=1&display=allpossible&sort=name")
    compare_static("/division.php?date=2013-03-14&number=1&house=representatives&display=allpossible&sort=name")
    compare_static("/division.php?date=2013-03-14&number=1&house=senate&display=allpossible&sort=name")
    compare_static("/division.php?date=2013-03-14&number=1&sort=vote")
    compare_static("/division.php?date=2013-03-14&number=1&house=representatives&sort=vote")
    compare_static("/division.php?date=2013-03-14&number=1&house=senate&sort=vote")
    compare_static("/division.php?date=2013-03-14&number=1&display=allvotes&sort=vote")
    compare_static("/division.php?date=2013-03-14&number=1&house=representatives&display=allvotes&sort=vote")
    compare_static("/division.php?date=2013-03-14&number=1&house=senate&display=allvotes&sort=vote")
    compare_static("/division.php?date=2013-03-14&number=1&display=allpossible&sort=vote")
    compare_static("/division.php?date=2013-03-14&number=1&house=representatives&display=allpossible&sort=vote")
    compare_static("/division.php?date=2013-03-14&number=1&house=senate&display=allpossible&sort=vote")
    compare_static("/division.php?date=2013-03-14&number=1&sort=constituency")
    compare_static("/division.php?date=2013-03-14&number=1&house=representatives&sort=constituency")
    compare_static("/division.php?date=2013-03-14&number=1&house=senate&sort=constituency")
    compare_static("/division.php?date=2013-03-14&number=1&display=allvotes&sort=constituency")
    compare_static("/division.php?date=2013-03-14&number=1&house=representatives&display=allvotes&sort=constituency")
    compare_static("/division.php?date=2013-03-14&number=1&house=senate&display=allvotes&sort=constituency")
    compare_static("/division.php?date=2013-03-14&number=1&display=allpossible&sort=constituency")
    compare_static("/division.php?date=2013-03-14&number=1&house=representatives&display=allpossible&sort=constituency")
    compare_static("/division.php?date=2013-03-14&number=1&house=senate&display=allpossible&sort=constituency")

    compare_static("/division.php?date=2006-12-06&number=3&house=representatives")
    # house=representatives or house=senate appears twice. This is obviously wrong
    compare_static("/division.php?date=2006-12-06&number=3&mpn=Tony_Abbott&mpc=Warringah&house=representatives&house=representatives")
    compare_static("/division.php?date=2006-12-06&number=3&mpn=Kevin_Rudd&mpc=Griffith&house=representatives&house=representatives")
    compare_static("/division.php?date=2013-03-14&number=1&mpn=Christine_Milne&mpc=Senate&house=senate&house=senate")

    compare_static("/division.php?date=2013-03-14&number=1&display=policies", true)
    compare_static("/division.php?date=2013-03-14&number=1&house=representatives&display=policies", true)
    compare_static("/division.php?date=2013-03-14&number=1&house=senate&display=policies", true)
    compare_static("/division.php?date=2009-11-25&number=8&house=senate&display=policies", true)
    compare_static("/division.php?date=2009-11-25&number=8&house=senate&display=policies&dmp=2", true)
    compare_static("/division.php?date=2009-11-25&number=8&house=senate&display=policies&dmp=1", true)
    compare_static("/division.php?date=2006-12-06&number=3&display=policies", true)
  end

  it "#index" do
    compare_static("/divisions.php")
    compare_static("/divisions.php?rdisplay=2007")
    compare_static("/divisions.php?rdisplay=2004")
    compare_static("/divisions.php?rdisplay=all")
    compare_static("/divisions.php?rdisplay2=rebels")
    compare_static("/divisions.php?rdisplay=2007&rdisplay2=rebels")
    compare_static("/divisions.php?rdisplay=2004&rdisplay2=rebels")
    compare_static("/divisions.php?rdisplay=all&rdisplay2=rebels")
    compare_static("/divisions.php?house=representatives")
    compare_static("/divisions.php?rdisplay=2007&house=representatives")
    compare_static("/divisions.php?rdisplay=2004&house=representatives")
    compare_static("/divisions.php?rdisplay=all&house=representatives")
    compare_static("/divisions.php?rdisplay2=rebels&house=representatives")
    compare_static("/divisions.php?rdisplay=2007&rdisplay2=rebels&house=representatives")
    compare_static("/divisions.php?rdisplay=2004&rdisplay2=rebels&house=representatives")
    compare_static("/divisions.php?rdisplay=all&rdisplay2=rebels&house=representatives")
    compare_static("/divisions.php?house=senate")
    compare_static("/divisions.php?rdisplay=2007&house=senate")
    compare_static("/divisions.php?rdisplay=2004&house=senate")
    compare_static("/divisions.php?rdisplay=all&house=senate")
    compare_static("/divisions.php?rdisplay2=rebels&house=senate")
    compare_static("/divisions.php?rdisplay=2007&rdisplay2=rebels&house=senate")
    compare_static("/divisions.php?rdisplay=2004&rdisplay2=rebels&house=senate")
    compare_static("/divisions.php?rdisplay=all&rdisplay2=rebels&house=senate")

    compare_static("/divisions.php?sort=subject")
    compare_static("/divisions.php?rdisplay=2007&sort=subject")
    compare_static("/divisions.php?rdisplay=2004&sort=subject")
    compare_static("/divisions.php?rdisplay=all&sort=subject")
    compare_static("/divisions.php?rdisplay2=rebels&sort=subject")
    compare_static("/divisions.php?rdisplay=2007&rdisplay2=rebels&sort=subject")
    compare_static("/divisions.php?rdisplay=2004&rdisplay2=rebels&sort=subject")
    compare_static("/divisions.php?rdisplay=all&rdisplay2=rebels&sort=subject")
    compare_static("/divisions.php?house=representatives&sort=subject")
    compare_static("/divisions.php?rdisplay=2007&house=representatives&sort=subject")
    compare_static("/divisions.php?rdisplay=2004&house=representatives&sort=subject")
    compare_static("/divisions.php?rdisplay=all&house=representatives&sort=subject")
    compare_static("/divisions.php?rdisplay2=rebels&house=representatives&sort=subject")
    compare_static("/divisions.php?rdisplay=2007&rdisplay2=rebels&house=representatives&sort=subject")
    compare_static("/divisions.php?rdisplay=2004&rdisplay2=rebels&house=representatives&sort=subject")
    compare_static("/divisions.php?rdisplay=all&rdisplay2=rebels&house=representatives&sort=subject")
    compare_static("/divisions.php?house=senate&sort=subject")
    compare_static("/divisions.php?rdisplay=2007&house=senate&sort=subject")
    compare_static("/divisions.php?rdisplay=2004&house=senate&sort=subject")
    compare_static("/divisions.php?rdisplay=all&house=senate&sort=subject")
    compare_static("/divisions.php?rdisplay2=rebels&house=senate&sort=subject")
    compare_static("/divisions.php?rdisplay=2007&rdisplay2=rebels&house=senate&sort=subject")
    compare_static("/divisions.php?rdisplay=2004&rdisplay2=rebels&house=senate&sort=subject")
    compare_static("/divisions.php?rdisplay=all&rdisplay2=rebels&house=senate&sort=subject")

    compare_static("/divisions.php?sort=rebellions")
    compare_static("/divisions.php?rdisplay=2007&sort=rebellions")
    compare_static("/divisions.php?rdisplay=2004&sort=rebellions")
    compare_static("/divisions.php?rdisplay=all&sort=rebellions")
    compare_static("/divisions.php?rdisplay2=rebels&sort=rebellions")
    compare_static("/divisions.php?rdisplay=2007&rdisplay2=rebels&sort=rebellions")
    compare_static("/divisions.php?rdisplay=2004&rdisplay2=rebels&sort=rebellions")
    compare_static("/divisions.php?rdisplay=all&rdisplay2=rebels&sort=rebellions")
    compare_static("/divisions.php?house=representatives&sort=rebellions")
    compare_static("/divisions.php?rdisplay=2007&house=representatives&sort=rebellions")
    compare_static("/divisions.php?rdisplay=2004&house=representatives&sort=rebellions")
    compare_static("/divisions.php?rdisplay=all&house=representatives&sort=rebellions")
    compare_static("/divisions.php?rdisplay2=rebels&house=representatives&sort=rebellions")
    compare_static("/divisions.php?rdisplay=2007&rdisplay2=rebels&house=representatives&sort=rebellions")
    compare_static("/divisions.php?rdisplay=2004&rdisplay2=rebels&house=representatives&sort=rebellions")
    compare_static("/divisions.php?rdisplay=all&rdisplay2=rebels&house=representatives&sort=rebellions")
    compare_static("/divisions.php?house=senate&sort=rebellions")
    compare_static("/divisions.php?rdisplay=2007&house=senate&sort=rebellions")
    compare_static("/divisions.php?rdisplay=2004&house=senate&sort=rebellions")
    compare_static("/divisions.php?rdisplay=all&house=senate&sort=rebellions")
    compare_static("/divisions.php?rdisplay2=rebels&house=senate&sort=rebellions")
    compare_static("/divisions.php?rdisplay=2007&rdisplay2=rebels&house=senate&sort=rebellions")
    compare_static("/divisions.php?rdisplay=2004&rdisplay2=rebels&house=senate&sort=rebellions")
    compare_static("/divisions.php?rdisplay=all&rdisplay2=rebels&house=senate&sort=rebellions")

    compare_static("/divisions.php?sort=turnout")
    compare_static("/divisions.php?rdisplay=2007&sort=turnout")
    compare_static("/divisions.php?rdisplay=2004&sort=turnout")
    compare_static("/divisions.php?rdisplay=all&sort=turnout")
    compare_static("/divisions.php?rdisplay2=rebels&sort=turnout")
    compare_static("/divisions.php?rdisplay=2007&rdisplay2=rebels&sort=turnout")
    compare_static("/divisions.php?rdisplay=2004&rdisplay2=rebels&sort=turnout")
    compare_static("/divisions.php?rdisplay=all&rdisplay2=rebels&sort=turnout")
    compare_static("/divisions.php?house=representatives&sort=turnout")
    compare_static("/divisions.php?rdisplay=2007&house=representatives&sort=turnout")
    compare_static("/divisions.php?rdisplay=2004&house=representatives&sort=turnout")
    compare_static("/divisions.php?rdisplay=all&house=representatives&sort=turnout")
    compare_static("/divisions.php?rdisplay2=rebels&house=representatives&sort=turnout")
    compare_static("/divisions.php?rdisplay=2007&rdisplay2=rebels&house=representatives&sort=turnout")
    compare_static("/divisions.php?rdisplay=2004&rdisplay2=rebels&house=representatives&sort=turnout")
    compare_static("/divisions.php?rdisplay=all&rdisplay2=rebels&house=representatives&sort=turnout")
    compare_static("/divisions.php?house=senate&sort=turnout")
    compare_static("/divisions.php?rdisplay=2007&house=senate&sort=turnout")
    compare_static("/divisions.php?rdisplay=2004&house=senate&sort=turnout")
    compare_static("/divisions.php?rdisplay=all&house=senate&sort=turnout")
    compare_static("/divisions.php?rdisplay2=rebels&house=senate&sort=turnout")
    compare_static("/divisions.php?rdisplay=2007&rdisplay2=rebels&house=senate&sort=turnout")
    compare_static("/divisions.php?rdisplay=2004&rdisplay2=rebels&house=senate&sort=turnout")
    compare_static("/divisions.php?rdisplay=all&rdisplay2=rebels&house=senate&sort=turnout")

    compare_static("/divisions.php?rdisplay2=Australian%20Labor%20Party_party&house=representatives")
    compare_static("/divisions.php?rdisplay2=Liberal%20Party_party&house=representatives")
    compare_static("/divisions.php?rdisplay2=Australian%20Greens_party&house=senate")

    compare_static("/divisions.php?rdisplay2=Australian%20Labor%20Party_party&house=representatives&sort=subject")
    compare_static("/divisions.php?rdisplay2=Liberal%20Party_party&house=representatives&sort=subject")
    compare_static("/divisions.php?rdisplay2=Australian%20Greens_party&house=senate&sort=subject")

    compare_static("/divisions.php?rdisplay2=Australian%20Labor%20Party_party&house=representatives&sort=rebellions")
    compare_static("/divisions.php?rdisplay2=Liberal%20Party_party&house=representatives&sort=rebellions")
    compare_static("/divisions.php?rdisplay2=Australian%20Greens_party&house=senate&sort=rebellions")

    compare_static("/divisions.php?rdisplay2=Australian%20Labor%20Party_party&house=representatives&sort=turnout")
    compare_static("/divisions.php?rdisplay2=Liberal%20Party_party&house=representatives&sort=turnout")
    compare_static("/divisions.php?rdisplay2=Australian%20Greens_party&house=senate&sort=turnout")

    compare_static("/divisions.php?rdisplay=2007&rdisplay2=Australian%20Labor%20Party_party&house=representatives")
  end

  describe '#edit' do
    it { compare_static '/account/wiki.php?type=motion&date=2009-11-25&number=8&house=senate&rr=%2Fdivision.php%3Fdate%3D2009-11-25%26number%3D8%26house%3Dsenate', true }
    it { compare_static '/account/wiki.php?type=motion&date=2013-03-14&number=1&house=representatives&rr=%2Fdivision.php%3Fdate%3D2013-03-14%26number%3D1%26house%3Drepresentatives', true}
  end

  describe '#update' do
    it { compare_post '/account/wiki.php?type=motion&date=2009-11-25&number=8&house=senate&rr=%2Fdivision.php%3Fdate%3D2009-11-25%26number%3D8%26house%3Dsenate', true, submit: 'Save', newtitle: 'A lovely new title', newdescription: 'And a great new description' }
    it { compare_post '/account/wiki.php?type=motion&date=2009-11-25&number=8&house=senate', true, submit: 'Save', newtitle: 'A lovely new title', newdescription: 'And a great new description' }
  end

  describe '#add_policy_vote' do
    it 'makes no changes' do
      compare_post '/division.php?date=2006-12-06&number=3&display=policies&dmp=2', true, submit: 'Update', vote2: 'no'
      compare_post '/division.php?date=2009-11-25&number=8&house=senate&display=policies&dmp=2', true, submit: 'Update', vote2: '--'
    end

    it 'updates an existing policy division' do
      compare_static '/division.php?date=2013-03-14&number=1&house=senate&display=policies&dmp=2', true, submit: 'Update', vote2: 'aye3'
    end

    it 'creates a new policy division' do
      compare_static '/division.php?date=2013-03-14&number=1&display=policies&dmp=2', true, submit: 'Update', vote2: 'aye3'
      compare_static '/division.php?date=2013-03-14&number=1&house=senate&display=policies&dmp=1', true, submit: 'Update', vote1: 'aye3'
    end

    it 'removes a policy division' do
      compare_static('/division.php?date=2013-03-14&number=1&dmp=1&display=policies', true, submit: 'Update', vote1: '--')
    end

    it 'recalculates MP agreement percentages' do
      # Just post to Rails
      compare_static '/division.php?date=2013-03-14&number=1&house=senate&display=policies&dmp=2', true, submit: 'Update', vote2: 'aye3'
      # Rails does the recalculation in a background job so make sure that's done
      Delayed::Worker.new.work_off
      # Compare Rails what the PHP app would generate (because it would rebuild it's cache)
      compare_static '/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate', true
    end
  end
end
