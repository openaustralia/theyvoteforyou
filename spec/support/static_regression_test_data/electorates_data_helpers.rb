module StaticRegressionTestDataHelpers
  def create_electorates
    create(
      :electorate,
      id: 1,
      name: "Warringah",
      main_name: true,
      from_date: "1000-1-1",
      to_date: "9999-12-31",
      house: "representatives"
    )

    create(
      :electorate,
      id: 63,
      name: "Griffith",
      main_name: true,
      from_date: "1000-1-1",
      to_date: "9999-12-31",
      house: "representatives"
    )

    create(
      :electorate,
      id: 138,
      name: "Bennelong",
      main_name: true,
      from_date: "1000-1-1",
      to_date: "9999-12-31",
      house: "representatives"
    )

    create(
      :electorate,
      id: 101,
      name: "Lowe",
      main_name: true,
      from_date: "1000-01-01",
      to_date: "9999-12-31",
      house: "representatives"
    )

    create(
      :electorate,
      id: 14,
      name: "Chifley",
      main_name: true,
      from_date: "1000-01-01",
      to_date: "9999-12-31",
      house: "representatives"
    )
  end
end
