# frozen_string_literal: true

module DivisionSummaryPipeline
  # Amendments the chair put without anyone moving them in the chamber. Under a limitation of
  # debate, amendments circulated beforehand are put when the time expires, nobody moving them
  # (Senate Guide No. 17; House S.O. 85(c) treats circulated amendments "as if they had been
  # moved"). That is ordinary procedure, not something missing, so a draft says they were
  # circulated and put, never that someone moved them.
  #
  # - by: who circulated them, in Hansard's words ("the Australian Greens", "Senator Example"), or
  #   nil when Hansard does not say
  # - member: the ResolvedMember when by names a member, otherwise nil
  # - plural: whether the question put more than one amendment
  Circulation = Data.define(:by, :member, :plural)
end
