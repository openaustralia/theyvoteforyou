# frozen_string_literal: true

require Rails.root.join("app/helpers/path_helper")

namespace :application do
  namespace :export do
    # Data required for visualisation at https://github.com/openaustralia/visualise-votes-mds/blob/main/notebook.ipynb
    desc "Export csv files required for voting visualisation"
    task voting_visualisation: :environment do
      def write_distances(file, members)
        file << %w[person1_id person2_id distance_b].to_csv
        people_ids = members.pluck(:person_id)
        PeopleDistance.where(person1: people_ids, person2: people_ids).find_each do |d|
          file << [d.person1_id, d.person2_id, d.distance_b].to_csv
        end
      end

      def write_people(file, members)
        file << %w[id name party].to_csv
        members.find_each do |m|
          file << [m.person.id, m.person.name, m.person.latest_member.party].to_csv
        end
      end

      members = Member.current.where(house: "representatives")
      File.open("representatives_distances.csv", "w") { |f| write_distances(f, members) }
      File.open("representatives_people.csv", "w") { |f| write_people(f, members) }

      members = Member.current.where(house: "senate")
      File.open("senate_distances.csv", "w") { |f| write_distances(f, members) }
      File.open("senate_people.csv", "w") { |f| write_people(f, members) }
    end
  end
end
