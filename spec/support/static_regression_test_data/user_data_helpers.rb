module StaticRegressionTestDataHelpers
  def create_users
    create(
      :user,
      id: 1,
      name: "Henare Degan",
      email: "henare@oaf.org.au",
      confirmed_at: DateTime.parse("2013-10-20 10:10:53")
    )
  end
end
