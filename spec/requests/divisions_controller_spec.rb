# frozen_string_literal: true

require "spec_helper"

describe DivisionsController, type: :request do
  include HTMLCompareHelper
  include_context "with fixtures"

  describe "#show" do
    it do
      division_representatives_2006_12_06_3
      policy2
      member_john_howard
      compare_static("/divisions/representatives/2006-12-06/3")
    end

    it do
      division_representatives_2013_03_14_1
      policy1
      member_tony_abbott
      member_john_alexander
      compare_static("/divisions/representatives/2013-03-14/1")
    end

    it do
      division_senate_2013_03_14_1
      policy2
      policy3
      compare_static("/divisions/senate/2013-03-14/1")
    end
  end

  describe "#index" do
    before do
      division_representatives_2006_12_06_3
      division_senate_2009_11_25_8
      division_senate_2009_11_30_8
      division_senate_2009_12_30_8
      division_representatives_2013_03_14_1
      division_senate_2013_03_14_1
    end

    it { compare_static("/divisions/all/2007") }
    it { compare_static("/divisions/all/2004") }
    it { compare_static("/divisions/all") }
    it { compare_static("/divisions/representatives") }
    it { compare_static("/divisions/representatives/2007") }
    it { compare_static("/divisions/representatives/2004") }
    it { compare_static("/divisions/senate") }
    it { compare_static("/divisions/senate/2007") }
    it { compare_static("/divisions/senate/2004") }

    it { compare_static("/divisions/all/2007?sort=subject") }
    it { compare_static("/divisions/all/2004?sort=subject") }
    it { compare_static("/divisions/all?sort=subject") }
    it { compare_static("/divisions/representatives?sort=subject") }
    it { compare_static("/divisions/representatives/2007?sort=subject") }
    it { compare_static("/divisions/representatives/2004?sort=subject") }
    it { compare_static("/divisions/senate?sort=subject") }
    it { compare_static("/divisions/senate/2007?sort=subject") }
    it { compare_static("/divisions/senate/2004?sort=subject") }

    it { compare_static("/divisions/all/2007?sort=rebellions") }
    it { compare_static("/divisions/all/2004?sort=rebellions") }
    it { compare_static("/divisions/all?sort=rebellions") }
    it { compare_static("/divisions/representatives?sort=rebellions") }
    it { compare_static("/divisions/representatives/2007?sort=rebellions") }
    it { compare_static("/divisions/representatives/2004?sort=rebellions") }
    it { compare_static("/divisions/senate?sort=rebellions") }
    it { compare_static("/divisions/senate/2007?sort=rebellions") }
    it { compare_static("/divisions/senate/2004?sort=rebellions") }

    it { compare_static("/divisions/all/2007?sort=turnout") }
    it { compare_static("/divisions/all/2004?sort=turnout") }
    it { compare_static("/divisions/all?sort=turnout") }
    it { compare_static("/divisions/representatives?sort=turnout") }
    it { compare_static("/divisions/representatives/2007?sort=turnout") }
    it { compare_static("/divisions/representatives/2004?sort=turnout") }
    it { compare_static("/divisions/senate?sort=turnout") }
    it { compare_static("/divisions/senate/2007?sort=turnout") }
    it { compare_static("/divisions/senate/2004?sort=turnout") }
  end

  context "when logged in" do
    before do
      login_as(user)
    end

    describe "#show_policies" do
      before do
        policy1
        policy2
        policy3
      end

      it do
        division_representatives_2006_12_06_3
        compare_static("/divisions/representatives/2006-12-06/3/policies")
      end

      it do
        division_representatives_2013_03_14_1
        compare_static("/divisions/representatives/2013-03-14/1/policies")
      end

      it do
        division_senate_2009_11_25_8
        compare_static("/divisions/senate/2009-11-25/8/policies")
      end

      it do
        division_senate_2013_03_14_1
        compare_static("/divisions/senate/2013-03-14/1/policies")
      end
    end

    describe "#edit" do
      it do
        division_senate_2009_11_25_8
        compare_static "/divisions/senate/2009-11-25/8/edit"
      end

      it do
        division_representatives_2013_03_14_1
        compare_static "/divisions/representatives/2013-03-14/1/edit"
      end
    end

    describe "#update" do
      it do
        division_senate_2009_11_25_8
        compare_static "/divisions/senate/2009-11-25/8", form_params: { submit: "Save", newtitle: "A lovely new title", newdescription: "And a great new description" }
      end
    end
  end
end
