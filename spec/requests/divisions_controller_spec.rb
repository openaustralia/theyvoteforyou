# frozen_string_literal: true

require "spec_helper"

describe DivisionsController, type: :request do
  include HTMLCompareHelper
  fixtures :all

  describe "#show" do
    it { compare_static("/divisions/representatives/2006-12-06/3") }
    it { compare_static("/divisions/representatives/2013-03-14/1") }
    it { compare_static("/divisions/senate/2013-03-14/1") }

    it { compare_static("/divisions/representatives/2006-12-06/3/policies", true) }
    it { compare_static("/divisions/representatives/2013-03-14/1/policies", true) }
    it { compare_static("/divisions/representatives/2013-03-14/1/policies", false, false, "_2") }
    it { compare_static("/divisions/senate/2009-11-25/8/policies", true) }
    it { compare_static("/divisions/senate/2009-11-25/8/policies/1", true) }
    it { compare_static("/divisions/senate/2009-11-25/8/policies/2", true) }
    it { compare_static("/divisions/senate/2013-03-14/1/policies", true) }
    it { compare_static("/divisions/senate/2013-03-14/1/policies", false, false, "_2") }

    it { compare_static("/people/representatives/griffith/kevin_rudd/divisions/2006-12-06/3") }
    it { compare_static("/people/representatives/warringah/tony_abbott/divisions/2006-12-06/3") }
    it { compare_static("/people/senate/tasmania/christine_milne/divisions/2013-03-14/1") }
  end

  describe "#index" do
    it { compare_static("/divisions") }
    it { compare_static("/divisions/all/2007") }
    it { compare_static("/divisions/all/2004") }
    it { compare_static("/divisions.php?rdisplay=all") }
    it { compare_static("/divisions/representatives") }
    it { compare_static("/divisions/representatives/2007") }
    it { compare_static("/divisions/representatives/2004") }
    it { compare_static("/divisions.php?rdisplay=all&house=representatives") }
    it { compare_static("/divisions/senate") }
    it { compare_static("/divisions/senate/2007") }
    it { compare_static("/divisions/senate/2004") }
    it { compare_static("/divisions.php?rdisplay=all&house=senate") }

    it { compare_static("/divisions.php?sort=subject") }
    it { compare_static("/divisions/all/2007?sort=subject") }
    it { compare_static("/divisions/all/2004?sort=subject") }
    it { compare_static("/divisions.php?rdisplay=all&sort=subject") }
    it { compare_static("/divisions/representatives?sort=subject") }
    it { compare_static("/divisions/representatives/2007?sort=subject") }
    it { compare_static("/divisions/representatives/2004?sort=subject") }
    it { compare_static("/divisions.php?rdisplay=all&house=representatives&sort=subject") }
    it { compare_static("/divisions/senate?sort=subject") }
    it { compare_static("/divisions/senate/2007?sort=subject") }
    it { compare_static("/divisions/senate/2004?sort=subject") }
    it { compare_static("/divisions.php?rdisplay=all&house=senate&sort=subject") }

    it { compare_static("/divisions.php?sort=rebellions") }
    it { compare_static("/divisions/all/2007?sort=rebellions") }
    it { compare_static("/divisions/all/2004?sort=rebellions") }
    it { compare_static("/divisions.php?rdisplay=all&sort=rebellions") }
    it { compare_static("/divisions/representatives?sort=rebellions") }
    it { compare_static("/divisions/representatives/2007?sort=rebellions") }
    it { compare_static("/divisions/representatives/2004?sort=rebellions") }
    it { compare_static("/divisions.php?rdisplay=all&house=representatives&sort=rebellions") }
    it { compare_static("/divisions/senate?sort=rebellions") }
    it { compare_static("/divisions/senate/2007?sort=rebellions") }
    it { compare_static("/divisions/senate/2004?sort=rebellions") }
    it { compare_static("/divisions.php?rdisplay=all&house=senate&sort=rebellions") }

    it { compare_static("/divisions.php?sort=turnout") }
    it { compare_static("/divisions/all/2007?sort=turnout") }
    it { compare_static("/divisions/all/2004?sort=turnout") }
    it { compare_static("/divisions.php?rdisplay=all&sort=turnout") }
    it { compare_static("/divisions/representatives?sort=turnout") }
    it { compare_static("/divisions/representatives/2007?sort=turnout") }
    it { compare_static("/divisions/representatives/2004?sort=turnout") }
    it { compare_static("/divisions.php?rdisplay=all&house=representatives&sort=turnout") }
    it { compare_static("/divisions/senate?sort=turnout") }
    it { compare_static("/divisions/senate/2007?sort=turnout") }
    it { compare_static("/divisions/senate/2004?sort=turnout") }
    it { compare_static("/divisions.php?rdisplay=all&house=senate&sort=turnout") }

    it { compare_static("/parties/australian_labor_party/divisions/representatives") }
    it { compare_static("/parties/liberal_party/divisions/representatives") }
    it { compare_static("/parties/australian_greens/divisions/senate") }

    it { compare_static("/parties/australian_labor_party/divisions/representatives?sort=subject") }
    it { compare_static("/parties/liberal_party/divisions/representatives?sort=subject") }
    it { compare_static("/parties/australian_greens/divisions/senate?sort=subject") }

    it { compare_static("/parties/australian_labor_party/divisions/representatives?sort=rebellions") }
    it { compare_static("/parties/liberal_party/divisions/representatives?sort=rebellions") }
    it { compare_static("/parties/australian_greens/divisions/senate?sort=rebellions") }

    it { compare_static("/parties/australian_labor_party/divisions/representatives?sort=turnout") }
    it { compare_static("/parties/liberal_party/divisions/representatives?sort=turnout") }
    it { compare_static("/parties/australian_greens/divisions/senate?sort=turnout") }

    it { compare_static("/divisions.php?rdisplay=2007&rdisplay2=Australian%20Labor%20Party_party&house=representatives") }
  end

  describe "#edit" do
    it { compare_static "/account/wiki.php?type=motion&date=2009-11-25&number=8&house=senate&rr=%2Fdivision.php%3Fdate%3D2009-11-25%26number%3D8%26house%3Dsenate", true }
    it { compare_static "/account/wiki.php?type=motion&date=2013-03-14&number=1&house=representatives&rr=%2Fdivision.php%3Fdate%3D2013-03-14%26number%3D1%26house%3Drepresentatives", true }
  end

  describe "#update" do
    it { compare_static "/divisions/senate/2009-11-25/8", true, submit: "Save", newtitle: "A lovely new title", newdescription: "And a great new description" }
  end
end
