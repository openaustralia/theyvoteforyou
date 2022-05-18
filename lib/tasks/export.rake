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

    # We also want to export a different version of the distances file which
    # limits results to the term of the last parliament and includes the absolute number of
    # votes that were different and the same
    desc "Export csv files for voting visualisation for recent parliamentary term"
    task voting_vis_46th_parliament: :environment do
      people = Member.current.where(house: "representatives").map(&:person)
      File.open("distances_46th_parliament.csv", "w") do |file|
        progress = ProgressBar.create(total: people.count, format: "%t: |%B| %E %a")
        file << %w[person1_id person2_id same differ].to_csv
        people.each do |person1|
          people.select { |p| p.id >= person1.id }.each do |person2|
            # https://en.wikipedia.org/wiki/46th_Parliament_of_Australia
            date = Date.new(2019, 7, 2)..Date.new(2022, 4, 11)
            r = PeopleDistance.calculate_distances(person1, person2, date)
            file << [person1.id, person2.id, r[:nvotessame], r[:nvotesdiffer]].to_csv
            file << [person2.id, person1.id, r[:nvotessame], r[:nvotesdiffer]].to_csv
          end
          progress.increment
        end
      end
    end
  end
end
