class Person
  attr_reader :id

  def initialize(params)
    @id = params[:id]
  end

  # TODO When Person becomes a table in the db make this an association
  def members
    Member.where(person: id)
  end

  # TODO When Person becomes a table in the db make this an association
  def policy_distances
    PolicyMemberDistance.where(person: id)
  end

  def member_who_voted_on_division(division)
    latest_member = members.order(entered_house: :desc).first
    # What we have now in @member is a member related to the person that voted in division but @member wasn't necessarily
    # current when @division took place. So, let's fix this
    # We're doing this the same way as the php which doesn't seem necessarily the best way
    # TODO Figure what is the best way
    new_member = members.find do |member|
      member.vote_on_division_with_tell(division) != "absent"
    end
    new_member || latest_member
  end

  # Find the member that relates to a given policy
  # Let's just step through the votes of the policy and find the first matching member
  def member_for_policy(policy)
    policy.divisions.each do |division|
      member = members.current_on(division.date).first
      return member if member
    end
    # If we can't find a member just return the original
    self
  end
end
