require 'spec_helper'

describe ElectoratesController, :type => :controller do
  describe "#show" do
    describe "constituency redirect to base url" do
      before :each do
        Member.create!(constituency: "Bennelong", gid: "", source_gid: "", first_name: "",
          last_name: "", title: "", party: "", house: "commons")
      end

      it do
        get :show, mpc: "Bennelong", house: "representatives", display: "allvotes"
        expect(response).to redirect_to "/mp.php?house=representatives&mpc=Bennelong"
      end

      it do
        get :show, mpc: "Bennelong", house: "representatives", dmp: 1
        expect(response).to redirect_to "/mp.php?house=representatives&mpc=Bennelong"
      end
    end
  end
end
