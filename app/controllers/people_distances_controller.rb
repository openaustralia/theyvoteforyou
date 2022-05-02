# frozen_string_literal: true

class PeopleDistancesController < ApplicationController
  def show
    @member1 = Member.find_with_url_params(house: params[:house], mpc: params[:mpc], mpn: params[:mpn])
    @member2 = Member.find_with_url_params(house: params[:house2], mpc: params[:mpc2], mpn: params[:mpn2])
    return render "members/member_not_found", status: :not_found if @member1.nil? || @member2.nil?

    canonical_member1 = @member1.person.latest_member
    canonical_member2 = @member2.person.latest_member
    if canonical_member1 != @member1 || canonical_member2 != @member2
      redirect_to canonical_member1.url_params.merge(
        mpc2: canonical_member2.url_electorate.downcase,
        mpn2: canonical_member2.url_name.downcase
      )
      return
    end

    @person_distance = PeopleDistance.find_by(person1: @member1.person, person2: @member2.person)

    policy_ids_at_least_once_differently = PolicyDivision.where(division: @person_distance.divisions_different).published.group(:policy_id).pluck(:policy_id).to_set
    policy_ids_at_least_once_same = PolicyDivision.where(division: @person_distance.divisions_same).published.group(:policy_id).pluck(:policy_id).to_set
    policy_ids_different_and_same = policy_ids_at_least_once_differently & policy_ids_at_least_once_same
    policy_ids_all_different = policy_ids_at_least_once_differently - policy_ids_different_and_same
    policy_ids_all_same = policy_ids_at_least_once_same - policy_ids_different_and_same
    @policies_all_same = Policy.find(policy_ids_all_same.to_a)
    @policies_all_different = Policy.find(policy_ids_all_different.to_a)
    @policies_different_and_same = Policy.find(policy_ids_different_and_same.to_a)
  end
end
