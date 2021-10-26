# frozen_string_literal: true

class LeftReasonAllowEmptyStrings < ActiveRecord::Migration
  def self.up
    # Active record doesn't natively support enums, have to do it manually.
    # Unfortunately mysql doesn't allow you to just add a value to an enum, you
    # have to respecify the whole enum.
    # execute "alter table pw_mp modify column left_reason enum('', 'unknown','still_in_office','general_election','general_election_standing','general_election_notstanding','changed_party','died','declared_void','resigned','disqualified','became_peer') NOT NULL DEFAULT 'unknown'";
  end

  def self.down
    # execute "alter table pw_mp modify column left_reason enum('unknown','still_in_office','general_election','general_election_standing','general_election_notstanding','changed_party','died','declared_void','resigned','disqualified','became_peer') NOT NULL DEFAULT 'unknown'";
  end
end
