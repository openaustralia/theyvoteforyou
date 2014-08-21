class MemberInfo < ActiveRecord::Base
  self.table_name = "pw_cache_mpinfo"

  belongs_to :member, foreign_key: "mp_id"

  def self.update_all!
    rebellions = Member.all_rebellion_counts
    tells = Member.all_tells_counts
    votes_attended = Member.all_votes_attended_counts
    votes_possible = Member.all_votes_possible_counts
    aye_majority = Member.all_aye_majority_counts

    Member.all.ids.each do |id|
      # TODO Give MemberInfo a primary key so that we can do this more sensibly
      MemberInfo.transaction do
        MemberInfo.where(mp_id: id).delete_all
        MemberInfo.create(mp_id: id,
          rebellions: rebellions[id] || 0, tells: tells[id] || 0,
          votes_attended: votes_attended[id] || 0, votes_possible: votes_possible[id] || 0,
          aye_majority: aye_majority[id] || 0)
      end
    end
  end
end
