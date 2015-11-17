module DataLoader
  module Ukraine
    class People
      PEOPLE_URL = ENV["DEBUG_URL"] || "https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/data/Ukraine/Verkhovna_Rada/ep-popolo-v1.0.json"

      def self.load!
        DataLoader::Ukraine::Popolo.load!(PEOPLE_URL)
      end
    end
  end
end
