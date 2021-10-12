# frozen_string_literal: true

require "spec_helper"

describe DivisionsController, type: :controller do
  describe "#index" do
    # TODO: Remove this hack to delete fixtures
    before :each do
      Division.delete_all
      Member.delete_all
    end

    let!(:december_2016_division) { create(:division, date: Date.new(2016, 12, 25)) }
    let!(:june_2016_division) { create(:division, date: Date.new(2016, 0o6, 0o1)) }
    let!(:older_division) { create(:division, date: Date.new(2013, 0o4, 29)) }

    let!(:representative) { create(:member, house: "representatives", constituency: "Newtown", first_name: "Jane", last_name: "Lo") }

    context "when there are no parameters" do
      it "should render index template with divisions of the same year as the last one stored" do
        get :index

        expect(response).to render_template "divisions/index"
        expect(response.status).to be 200
        expect(assigns(:divisions)).to eq([december_2016_division, june_2016_division])
      end
    end

    context "when request has an invalid date as a parameter" do
      it "should return generic 404 page" do
        get :index, params: { date: "2017-13-22", house: "representatives" }

        expect(response).to render_template "home/error_404"
        expect(response.status).to be 404
      end
    end

    context "when request has an date parameter with an incorrect format" do
      it "should return generic 404 page" do
        get :index, params: { date: "2017-12-222", house: "representatives" }

        expect(response).to render_template "home/error_404"
        expect(response.status).to be 404
      end
    end

    context "when the date parameter is a full date" do
      context "and date matches divisions already stored" do
        it "should render index template with selected divisions" do
          get :index, params: { date: "2016-06-01", house: "representatives" }

          expect(response).to render_template "divisions/index"
          expect(response.status).to be 200
          expect(assigns(:divisions)).to eq([june_2016_division])
        end
      end

      context "and date does not match any divisions" do
        it "should render index template with empty divisions" do
          get :index, params: { date: "2017-02-02", house: "representatives" }

          expect(response).to render_template "divisions/index"
          expect(response.status).to be 200
          expect(assigns(:divisions)).to be_empty
        end
      end
    end

    context "when the date parameter is just a year" do
      context "and date matches divisions already stored" do
        it "should render index template with selected divisions" do
          get :index, params: { date: "2016", house: "representatives" }

          expect(response).to render_template "divisions/index"
          expect(response.status).to be 200
          expect(assigns(:divisions)).to eq([december_2016_division, june_2016_division])
        end
      end

      context "and date does not match any divisions" do
        it "should render index template with empty divisions" do
          get :index, params: { date: "2017", house: "representatives" }

          expect(response).to render_template "divisions/index"
          expect(response.status).to be 200
          expect(assigns(:divisions)).to be_empty
        end
      end
    end

    context "when the date parameter is just a year and a month (YYYY-MM)" do
      context "and date matches divisions already stored" do
        it "should render index template with selected divisions" do
          get :index, params: { date: "2016-12", house: "representatives" }

          expect(response).to render_template "divisions/index"
          expect(response.status).to be 200
          expect(assigns(:divisions)).to eq([december_2016_division])
        end
      end

      context "and date does not match any divisions" do
        it "should render index template with empty divisions" do
          get :index, params: { date: "2016-05", house: "representatives" }

          expect(response).to render_template "divisions/index"
          expect(response.status).to be 200
          expect(assigns(:divisions)).to be_empty
        end
      end
    end

    context "when request to see votes from a member" do
      context "and no date is specified" do
        it "should get votes based on last year on divisions table" do
          get :index, params: { mpc: "newtown", mpn: "jane_lo", house: "representatives" }

          expect(response).to render_template "divisions/index_with_member"
          expect(response.status).to be 200
          expect(assigns(:member)).to eq(representative)
          expect(assigns(:date_start)).to eq(Date.new(2016, 0o1, 0o1))
          expect(assigns(:date_end)).to eq(Date.new(2017, 0o1, 0o1))
          expect(assigns(:date_range)).to eq(:year)
          expect(assigns(:divisions)).to eq([december_2016_division, june_2016_division])
        end
      end

      context "and a date is specified" do
        context "and date is valid" do
          it "should get votes based on the date specified" do
            get :index, params: { mpc: "newtown", mpn: "jane_lo", house: "representatives", date: "2013" }

            expect(response).to render_template "divisions/index_with_member"
            expect(response.status).to be 200
            expect(assigns(:member)).to eq(representative)
            expect(assigns(:date_start)).to eq(Date.new(2013, 0o1, 0o1))
            expect(assigns(:date_end)).to eq(Date.new(2014, 0o1, 0o1))
            expect(assigns(:date_range)).to eq(:year)
            expect(assigns(:divisions)).to eq([older_division])
          end
        end

        context "and date is not valid" do
          it "should return generic 404 page" do
            get :index, params: { mpc: "newtown", mpn: "christine_milne", house: "representatives", date: "2013-15-15" }

            expect(response).to render_template "home/error_404"
            expect(response.status).to be 404
          end
        end
      end
    end
  end

  describe "#show" do
    before :each do
      DivisionInfo.delete_all
      Whip.delete_all
      Vote.delete_all
      Member.delete_all
      Division.delete_all
    end

    let!(:one_division) { create(:division, date: Date.new(2017, 0o4, 0o6), house: "representatives", number: 100) }

    context "when request a specific division" do
      context "and parameters are match a division" do
        it "should load it" do
          get :show, params: { house: "representatives", date: "2017-04-06", number: 100 }

          expect(response).to render_template "divisions/show"
          expect(response.status).to be 200
          expect(assigns(:division)).to eq(one_division)
          expect(assigns(:whips)).to eq(one_division.whips)
          expect(assigns(:votes)).to eq(one_division.votes)
          expect(assigns(:rebellions)).to eq(one_division.votes.rebellious)
          expect(assigns(:members)).to eq([one_division.votes.first.member])
          expect(assigns(:members_vote_null)).to eq([])
        end
      end

      context "and parameters do not match a division" do
        it "should display a 404 page" do
          get :show, params: { house: "representatives", date: "2017-04-06", number: 101 }

          expect(response).to render_template "home/error_404"
          expect(response.status).to be 404
        end
      end
    end
  end
end
