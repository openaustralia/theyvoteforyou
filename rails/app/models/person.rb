class Person
  attr_reader :id

  def initialize(params)
    @id = params[:id]
  end

  def members
    Member.where(person: id)
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
end
