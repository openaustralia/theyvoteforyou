module StaticRegressionTestDataHelpers
  def create_wiki_motions
    create(
      :wiki_motion,
      id: 1,
      division_id: 1,
      text_body: "--- DIVISION TITLE ---\n\ntest\n\n--- MOTION EFFECT ---\n\nThis is some test text.\n\nIt might relate to bills containing HTML characters like the Carbon Pollution Reduction Scheme Bill&#160;2009 and Bills &#8212; National Disability Insurance Scheme Bill\n--- COMMENTS AND NOTES ---\n\n(put thoughts and notes for other researchers here)\n",
      user_id: 1,
      edit_date: DateTime.parse("2013-10-20 10:12:13")
    )

    create(
      :wiki_motion,
      id: 2,
      division_id: 347,
      text_body: "--- DIVISION TITLE ---\n\nProhibition of Human Cloning for Reproduction and the Regulation of Human Embryo Research Amendment Bill 2006 - Consideration in Detail\n\n--- MOTION EFFECT ---\n\n@MP voted aye to make this vote pass\r\n@MP voted no to make this vote fail\r\n\r\nThis is some test text. I'd like to illustrate formatting like ''italics'' and the following points:\r\n\r\n* My first point is simple\r\n* But I do have other points to\r\n* And sometimes I do go on\r\n\r\nTo back up my arguments I ensure that I link to official sources like the [http://aph.gov.au APH Official website].\r\n\r\n@This is a comment, it shouldn't be displayed.\r\n\r\nThere are other points where footnotes[1] are more useful for saying[2] more about my point.\r\n\r\n* [1] This was a good point.\r\n* [2] Saying as in describing.\n--- COMMENTS AND NOTES ---\n\n(put thoughts and notes for other researchers here)\n",
      user_id: 1,
      edit_date: DateTime.parse("2014-05-15 18:44:37")
    )
  end
end
