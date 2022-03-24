# frozen_string_literal: true

require "spec_helper"

describe DivisionsController, type: :request do
  include HTMLCompareHelper
  include_context "with fixtures"

  context "with individual setup" do
    # TODO: Remove this hack to delete fixtures
    before do
      remove_old_fixtures
    end

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

      describe "editing connected policies" do
        before do
          user
          policy1
          policy2
          policy3
        end

        it do
          division_representatives_2006_12_06_3
          compare_static("/divisions/representatives/2006-12-06/3/policies", signed_in: true)
        end

        it do
          division_representatives_2013_03_14_1
          compare_static("/divisions/representatives/2013-03-14/1/policies", signed_in: true)
        end

        it do
          division_senate_2009_11_25_8
          compare_static("/divisions/senate/2009-11-25/8/policies", signed_in: true)
        end

        it do
          division_senate_2009_11_25_8
          compare_static("/divisions/senate/2009-11-25/8/policies/1", signed_in: true)
        end

        it do
          division_senate_2009_11_25_8
          compare_static("/divisions/senate/2009-11-25/8/policies/2", signed_in: true)
        end

        it do
          division_senate_2013_03_14_1
          compare_static("/divisions/senate/2013-03-14/1/policies", signed_in: true)
        end
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

      it { compare_static("/divisions") }
      it { compare_static("/divisions/all/2007") }
      it { compare_static("/divisions/all/2004") }
      it { compare_static("/divisions/all") }
      it { compare_static("/divisions/representatives") }
      it { compare_static("/divisions/representatives/2007") }
      it { compare_static("/divisions/representatives/2004") }
      it { compare_static("/divisions/senate") }
      it { compare_static("/divisions/senate/2007") }
      it { compare_static("/divisions/senate/2004") }

      it { compare_static("/divisions?sort=subject") }
      it { compare_static("/divisions/all/2007?sort=subject") }
      it { compare_static("/divisions/all/2004?sort=subject") }
      it { compare_static("/divisions/all?sort=subject") }
      it { compare_static("/divisions/representatives?sort=subject") }
      it { compare_static("/divisions/representatives/2007?sort=subject") }
      it { compare_static("/divisions/representatives/2004?sort=subject") }
      it { compare_static("/divisions/senate?sort=subject") }
      it { compare_static("/divisions/senate/2007?sort=subject") }
      it { compare_static("/divisions/senate/2004?sort=subject") }

      it { compare_static("/divisions?sort=rebellions") }
      it { compare_static("/divisions/all/2007?sort=rebellions") }
      it { compare_static("/divisions/all/2004?sort=rebellions") }
      it { compare_static("/divisions/all?sort=rebellions") }
      it { compare_static("/divisions/representatives?sort=rebellions") }
      it { compare_static("/divisions/representatives/2007?sort=rebellions") }
      it { compare_static("/divisions/representatives/2004?sort=rebellions") }
      it { compare_static("/divisions/senate?sort=rebellions") }
      it { compare_static("/divisions/senate/2007?sort=rebellions") }
      it { compare_static("/divisions/senate/2004?sort=rebellions") }

      it { compare_static("/divisions?sort=turnout") }
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
  end

  context "with complete fixtures environment" do
    # TODO: Remove this hack to delete fixtures
    before do
      remove_old_fixtures
      add_new_fixtures
    end

    describe "#edit" do
      it { compare_static "/divisions/senate/2009-11-25/8/edit", signed_in: true }
      it { compare_static "/divisions/representatives/2013-03-14/1/edit", signed_in: true }
    end

    describe "#update" do
      it { compare_static "/divisions/senate/2009-11-25/8", signed_in: true, form_params: { submit: "Save", newtitle: "A lovely new title", newdescription: "And a great new description" } }
    end
  end
end
