module StaticRegressionTestDataHelpers
  def create_offices
    create(
      :office,
      id: 504,
      position: "Minister for Health and Ageing",
      from_date: DateTime.parse("2003-10-7"),
      to_date: DateTime.parse("2007-12-3"),
      person_id: 10001,
      dept: "",
      responsibility: ""
    )

    create(
      :office,
      id: 1201,
      position: "Shadow Minister for Families, Community Services, Indigenous Affairs and the Voluntary Sector",
      from_date: DateTime.parse("2007-12-6"),
      to_date: DateTime.parse("2008-9-22"),
      person_id: 10001,
      dept: "",
      responsibility: ""
    )

    create(
      :office,
      id: 1202,
      position: "Shadow Minister for Families, Housing, Community Services and Indigenous Affairs",
      from_date: DateTime.parse("2008-9-22"),
      to_date: DateTime.parse("2009-12-8"),
      person_id: 10001,
      dept: "",
      responsibility: ""
    )

    create(
      :office,
      id: 1200,
      position: "Leader of the Opposition",
      from_date: DateTime.parse("2009-12-8"),
      to_date: DateTime.parse("9999-12-31"),
      person_id: 10001,
      dept: "",
      responsibility: ""
    )

    create(
      :office,
      id: 380,
      position: "Prime Minister",
      from_date: DateTime.parse("2013-6-27"),
      to_date: DateTime.parse("9999-12-31"),
      person_id: 10552,
      dept: "",
      responsibility: ""
    )
  end
end
