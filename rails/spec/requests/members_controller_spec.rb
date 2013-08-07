require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe MembersController do
  include HTMLCompareHelper
  fixtures :electorates, :offices, :members, :member_infos
  #fixtures :electorates, :offices, :members, :member_infos, :divisions, :division_infos, :whips, :votes

  it "#index" do
    compare("/mps.php")
    compare("/mps.php?sort=lastname")
    compare("/mps.php?sort=constituency")
    compare("/mps.php?sort=party")
    compare("/mps.php?sort=rebellions")
    compare("/mps.php?sort=attendance")

    compare("/mps.php?house=senate")
    compare("/mps.php?house=senate&sort=lastname")
    compare("/mps.php?house=senate&sort=constituency")
    compare("/mps.php?house=senate&sort=party")
    compare("/mps.php?house=senate&sort=rebellions")
    compare("/mps.php?house=senate&sort=attendance")
  end

  it "#show" do
    compare("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives")
    compare("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives")
    compare("/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate")

    compare("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives&display=allvotes")
    compare("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives&display=allvotes")
    compare("/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate&display=allvotes")

    compare("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives&display=everyvote")
    compare("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives&display=everyvote")
    compare("/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate&display=everyvote")

    compare("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives&display=allfriends")
    compare("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives&display=allfriends")
    compare("/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate&display=allfriends")

    compare("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives&display=alldreams")
    compare("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives&display=alldreams")
    compare("/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate&display=alldreams")
  end
end
