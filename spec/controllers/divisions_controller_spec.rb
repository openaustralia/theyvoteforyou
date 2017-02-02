require 'spec_helper'

describe DivisionsController, :type => :controller do
  describe "#index" do
    before :each do
      Division.delete_all

      @division = Division.create(id: 5, name: "hey jude", date: Date.new(2016,12,25),
      number: 1, house: "representatives", source_url: "", debate_url: "", motion: "",
      source_gid: "", debate_gid: "")

      @other_division = Division.create(id: 6, name: "beautiful boy", date: Date.new(2016,06,01),
      number: 1, house: "representatives", source_url: "", debate_url: "", motion: "",
      source_gid: "", debate_gid: "")
    end

    context "when request has no parameters" do
      it "should return index page with all divisions" do
        get :index

        expect(response).to render_template "divisions/index"
        expect(response.status).to be 200
        expect(assigns(:divisions)).to eq([@division, @other_division])
      end
    end

    context "when request has a complete date parameter that exists in the database" do
      it "should return index page with selected divisions" do
        get :index, date: '2016-06-01', house: "representatives"

        expect(response).to render_template "divisions/index"
        expect(response.status).to be 200
        expect(assigns(:divisions)).to eq([@other_division])
      end
    end

    context "when request has a year parameter that exists in the database" do
      it "should return index page with selected divisions" do
        get :index, date: '2016', house: "representatives"

        expect(response).to render_template "divisions/index"
        expect(response.status).to be 200
        expect(assigns(:divisions)).to eq([@division, @other_division])
      end
    end

    context "when request has a year-month parameter that exists in the database" do
      it "should return index page with selected divisions" do
        get :index, date: '2016-12', house: "representatives"

        expect(response).to render_template "divisions/index"
        expect(response.status).to be 200
        expect(assigns(:divisions)).to eq([@division])
      end
    end

    context "when request has a complete date parameter that doest not exists in database" do
      it "should return index page with empty divisions" do
        get :index, date: '2017-02-02', house: "representatives"

        expect(response).to render_template "divisions/index"
        expect(response.status).to be 200
        expect(assigns(:divisions)).to be_empty
      end
    end

    context "when request has an invalid date as a parameter" do
      it "should return generic 404 page" do
        get :index, date: '2017-02-0222', house: "representatives"

        expect(response).to render_template "home/error_404"
        expect(response.status).to be 404
      end
    end
  end
end
