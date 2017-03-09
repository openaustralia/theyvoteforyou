require 'spec_helper'

describe DivisionsController, :type => :controller do
  describe "#index" do
    # TODO: Remove this hack to delete fixtures
    before :each do
      Division.delete_all
      Member.delete_all
    end

    let!(:december_2016_division)  { create(:division, date: Date.new(2016,12,25)) }
    let!(:june_2016_division)  { create(:division, date: Date.new(2016,06,01)) }
    let!(:older_division)  { create(:division, date: Date.new(2013,04,29)) }

    let!(:senator) { create(:member) }

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
        get :index, date: '2017-13-22', house: "representatives"

        expect(response).to render_template "home/error_404"
        expect(response.status).to be 404
      end
    end

    context "when request has an date parameter with an incorrect format" do
      it "should return generic 404 page" do
        get :index, date: '2017-12-222', house: "representatives"

        expect(response).to render_template "home/error_404"
        expect(response.status).to be 404
      end
    end

    context "when the date parameter is a full date" do
      context "and date matches divisions already stored" do
        it "should render index template with selected divisions" do
          get :index, date: '2016-06-01', house: "representatives"

          expect(response).to render_template "divisions/index"
          expect(response.status).to be 200
          expect(assigns(:divisions)).to eq([june_2016_division])
        end
      end

      context "and date does not match any divisions" do
        it "should render index template with empty divisions" do
          get :index, date: '2017-02-02', house: "representatives"

          expect(response).to render_template "divisions/index"
          expect(response.status).to be 200
          expect(assigns(:divisions)).to be_empty
        end
      end
    end

    context "when the date parameter is just a year" do
      context "and date matches divisions already stored" do
        it "should render index template with selected divisions" do
          get :index, date: '2016', house: "representatives"

          expect(response).to render_template "divisions/index"
          expect(response.status).to be 200
          expect(assigns(:divisions)).to eq([december_2016_division, june_2016_division])
        end
      end

      context "and date does not match any divisions" do
        it "should render index template with empty divisions" do
          get :index, date: '2017', house: "representatives"

          expect(response).to render_template "divisions/index"
          expect(response.status).to be 200
          expect(assigns(:divisions)).to be_empty
        end
      end
    end

    context "when the date parameter is just a year and a month (YYYY-MM)" do
      context "and date matches divisions already stored" do
        it "should render index template with selected divisions" do
          get :index, date: '2016-12', house: "representatives"

          expect(response).to render_template "divisions/index"
          expect(response.status).to be 200
          expect(assigns(:divisions)).to eq([december_2016_division])
        end
      end

      context "and date does not match any divisions" do
        it "should render index template with empty divisions" do
          get :index, date: '2016-05', house: "representatives"

          expect(response).to render_template "divisions/index"
          expect(response.status).to be 200
          expect(assigns(:divisions)).to be_empty
        end
      end
    end

    context "when request to see votes from a member" do
      context "and no date is specified" do
        it "should get votes based on last year on divisions table" do
          get :index, mpc: "tasmania", mpn: "christine_milne", house: "senate"

          expect(response).to render_template "divisions/index_with_member"
          expect(response.status).to be 200
          expect(assigns(:member)).to eq(senator)
          expect(assigns(:date_start)).to eq(Date.new(2016, 01, 01))
          expect(assigns(:date_end)).to eq(Date.new(2017, 01, 01))
        end
      end

      context "and a date is specified" do
        it "should get votes based on the date specified" do
          get :index, mpc: "tasmania", mpn: "christine_milne", house: "senate", date: "2013"

          expect(response).to render_template "divisions/index_with_member"
          expect(response.status).to be 200
          expect(assigns(:member)).to eq(senator)
          expect(assigns(:date_start)).to eq(Date.new(2013, 01, 01))
          expect(assigns(:date_end)).to eq(Date.new(2014, 01, 01))
        end
      end
    end
  end
end
