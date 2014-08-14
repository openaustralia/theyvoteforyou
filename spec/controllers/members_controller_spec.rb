require 'spec_helper'

describe MembersController, :type => :controller do
  describe "#show" do
    describe "constituency redirect to base url" do
      it do
        get :show, mpc: "Bennelong", house: "representatives", display: "allvotes"
        expect(response).to redirect_to "mp.php?mpc=Bennelong&house=representatives"
      end

      it do
        get :show, mpc: "Bennelong", house: "representatives", dmp: 1
        expect(response).to redirect_to "mp.php?mpc=Bennelong&house=representatives"
      end
    end
  end
end
